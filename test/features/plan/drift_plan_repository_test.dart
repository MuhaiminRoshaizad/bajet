import 'package:bajet/core/database/app_database.dart';
import 'package:bajet/features/ledger/data/drift_ledger_repository.dart';
import 'package:bajet/features/ledger/domain/ledger_models.dart';
import 'package:bajet/features/plan/data/drift_plan_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

DateTime d(int y, int m, int day) => DateTime.utc(y, m, day);

void main() {
  late AppDatabase db;
  late DriftPlanRepository plan;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    plan = DriftPlanRepository(db);
    // Bills paid and goals bought are logged to an account.
    await db.into(db.accounts).insert(AccountsCompanion.insert(kind: AccountKind.bank, name: 'Bank', color: 0xFF4A5866));
  });
  tearDown(() => db.close());

  test('reordering goals rewrites their priorities in the given order', () async {
    final laptop = await plan.addGoal(name: 'Laptop', price: 450000, targetDate: d(2026, 12, 1), priority: 1);
    final holiday = await plan.addGoal(name: 'Holiday', price: 200000, targetDate: d(2027, 3, 1), priority: 2);
    await plan.reorderGoals([holiday, laptop]);
    expect([for (final g in await plan.watchActiveGoals().first) g.name], ['Holiday', 'Laptop']);
  });

  test('a bought goal leaves the active list and is listed as achieved', () async {
    final laptop = await plan.addGoal(name: 'Laptop', price: 450000, targetDate: d(2026, 12, 1));
    await plan.markGoalBought(laptop, on: d(2026, 11, 20));
    expect(await plan.watchActiveGoals().first, isEmpty);
    final done = (await plan.watchAchievedGoals().first).single;
    expect((done.name, done.achievedOn), ('Laptop', d(2026, 11, 20)));
  });

  test('editing a bill or income changes it in place and keeps its kind', () async {
    final id = await plan.addRecurring(name: 'Pay', isIncome: true, amount: 300000, categoryKey: 'salary', nextDue: DateTime.utc(2026, 7, 25));
    final pay = (await plan.watchRecurring().first).single;
    await plan.updateRecurring(pay.copyWith(name: 'Salary', amount: 320000, nextDue: DateTime.utc(2026, 7, 24), windowDays: 4));

    final saved = (await plan.watchRecurring().first).single;
    expect((saved.id, saved.name, saved.amount, saved.categoryKey, saved.isIncome, saved.nextDue, saved.windowDays),
        (id, 'Salary', 320000, 'salary', true, DateTime.utc(2026, 7, 24), 4));
  });

  test('a goal can be edited, deleted and put back exactly as it was', () async {
    final id = await plan.addGoal(name: 'Laptop', price: 450000, targetDate: d(2026, 12, 1), priority: 2);
    final laptop = (await plan.watchActiveGoals().first).single;
    await plan.updateGoal(laptop.copyWith(name: 'New laptop', price: 480000));
    expect((await plan.watchActiveGoals().first).single.price, 480000);

    final edited = (await plan.watchActiveGoals().first).single;
    await plan.deleteGoal(id);
    expect(await plan.watchActiveGoals().first, isEmpty);
    await plan.restoreGoal(edited);
    final back = (await plan.watchActiveGoals().first).single;
    expect((back.id, back.name, back.price, back.priority), (id, 'New laptop', 480000, 2));
  });

  test('a bought goal restores as bought', () async {
    final id = await plan.addGoal(name: 'Laptop', price: 450000, targetDate: d(2026, 12, 1));
    await plan.markGoalBought(id, on: d(2026, 11, 20));
    final bought = (await plan.watchAchievedGoals().first).single;
    await plan.deleteGoal(id);
    await plan.restoreGoal(bought);
    expect((await plan.watchAchievedGoals().first).single.achievedOn, d(2026, 11, 20));
    expect(await plan.watchActiveGoals().first, isEmpty);
  });

  test('an event can be edited, deleted and put back exactly as it was', () async {
    final id = await plan.addEvent(name: 'Car service', isIncome: false, amount: 25000, categoryKey: 'transport', date: d(2026, 11, 20));
    final event = (await plan.watchEvents().first).single;
    await plan.updateEvent(event.copyWith(amount: 30000, countInProjection: false));
    final edited = (await plan.watchEvents().first).single;
    expect((edited.amount, edited.categoryKey, edited.countInProjection), (30000, 'transport', false));

    final removal = await plan.deleteEvent(id);
    expect(await plan.watchEvents().first, isEmpty);
    await plan.restoreEvent(removal);
    final back = (await plan.watchEvents().first).single;
    expect((back.id, back.amount, back.countInProjection), (id, 30000, false));
  });

  test('deleting a bill keeps its confirmed payments, and undo links them again', () async {
    final id = await plan.addRecurring(name: 'Rent', isIncome: false, amount: 50000, categoryKey: 'bills', nextDue: d(2026, 7, 1), windowDays: 2);
    await plan.confirmRecurring(id, paidOn: d(2026, 7, 1));

    final removal = await plan.deleteRecurring(id);
    expect(await plan.watchRecurring().first, isEmpty);
    final paid = await db.select(db.entries).getSingle();
    expect((paid.amount, paid.recurringItemId), (50000, null));

    await plan.restoreRecurring(removal);
    final back = (await plan.watchRecurring().first).single;
    expect((back.id, back.windowDays, back.nextDue), (id, 2, d(2026, 8, 1)));
    expect((await db.select(db.entries).getSingle()).recurringItemId, id);
  });

  test('marking a yearly event done moves it on a year; a one-off one is done', () async {
    final yearly = await plan.addEvent(name: 'Birthday', isIncome: false, amount: 10000, categoryKey: 'gifts', date: d(2026, 10, 30), repeatsYearly: true);
    final once = await plan.addEvent(name: 'Car service', isIncome: false, amount: 25000, categoryKey: 'transport', date: d(2026, 11, 20));
    await plan.setEventDone(yearly, done: true);
    await plan.setEventDone(once, done: true);
    final events = {for (final e in await plan.watchEvents().first) e.id: e};
    expect((events[yearly]!.done, events[yearly]!.date, events[yearly]!.repeatsYearly), (false, d(2027, 10, 30), true));
    expect(events[once]!.done, isTrue);
  });

  group('spending against an event', () {
    late DriftLedgerRepository ledger;
    setUp(() => ledger = DriftLedgerRepository(db));

    Future<int> spend(int amount, EventLink link) =>
        ledger.add(EntryDraft(day: d(2026, 10, 25), isIncome: false, amount: amount, categoryKey: 'food', event: link));

    test('counts against the occurrence it was for, and only that one', () async {
      final id = await plan.addEvent(name: 'Birthday', isIncome: false, amount: 10000, categoryKey: 'gifts', date: d(2026, 10, 30), repeatsYearly: true);
      await spend(4500, EventLink(id, d(2026, 10, 30)));
      await spend(2800, EventLink(id, d(2026, 10, 30)));
      var birthday = (await plan.watchEvents().first).single;
      expect((birthday.spent, birthday.outstanding), (7300, 2700));

      // Done moves it to next year, with a fresh budget.
      await plan.setEventDone(id, done: true);
      birthday = (await plan.watchEvents().first).single;
      expect((birthday.date, birthday.spent, birthday.outstanding), (d(2027, 10, 30), 0, 10000));
    });

    test('going over the budget leaves nothing still to come', () async {
      final id = await plan.addEvent(name: 'Birthday', isIncome: false, amount: 10000, categoryKey: 'gifts', date: d(2026, 10, 30));
      await spend(12000, EventLink(id, d(2026, 10, 30)));
      final birthday = (await plan.watchEvents().first).single;
      expect((birthday.spent, birthday.outstanding), (12000, 0));
    });

    test('moving the date keeps what was spent on it', () async {
      final id = await plan.addEvent(name: 'Birthday', isIncome: false, amount: 10000, categoryKey: 'gifts', date: d(2026, 10, 30));
      await spend(4500, EventLink(id, d(2026, 10, 30)));
      final birthday = (await plan.watchEvents().first).single;
      await plan.updateEvent(birthday.copyWith(date: d(2026, 11, 1)));
      expect((await plan.watchEvents().first).single.spent, 4500);
    });

    test('deleting the event keeps its entries, and undo links them again', () async {
      final id = await plan.addEvent(name: 'Birthday', isIncome: false, amount: 10000, categoryKey: 'gifts', date: d(2026, 10, 30));
      await spend(4500, EventLink(id, d(2026, 10, 30)));
      final removal = await plan.deleteEvent(id);
      expect((await db.select(db.entries).getSingle()).plannedEventId, isNull);

      await plan.restoreEvent(removal);
      expect((await plan.watchEvents().first).single.spent, 4500);
    });
  });

  test('a bill is paid from its own account, and moving it keeps what was paid where it was', () async {
    final cash = await db.into(db.accounts).insert(AccountsCompanion.insert(kind: AccountKind.cash, name: 'Cash', color: 0xFF6B3F24));
    final id = await plan.addRecurring(name: 'Rent', isIncome: false, amount: 50000, categoryKey: 'bills', nextDue: d(2026, 7, 1), accountId: cash);
    await plan.confirmRecurring(id, paidOn: d(2026, 7, 1));
    expect((await db.select(db.entries).getSingle()).accountId, cash);

    final rent = (await plan.watchRecurring().first).single;
    await plan.updateRecurring(rent.copyWith(accountId: 1));
    expect((await plan.watchRecurring().first).single.accountId, 1);
    expect((await db.select(db.entries).getSingle()).accountId, cash);
  });
}
