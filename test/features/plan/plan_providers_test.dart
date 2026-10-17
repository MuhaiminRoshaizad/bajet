import 'package:bajet/core/database/app_database.dart' show AccountKind, AccountsCompanion, AppDatabase, GoalStatus;
import 'package:bajet/core/database/database_provider.dart';
import 'package:bajet/features/ledger/domain/ledger_models.dart';
import 'package:bajet/features/ledger/presentation/ledger_providers.dart';
import 'package:bajet/features/plan/domain/plan_models.dart';
import 'package:bajet/features/plan/domain/plan_repository.dart';
import 'package:bajet/features/plan/presentation/plan_providers.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;
import 'package:flutter_test/flutter_test.dart';

DateTime d(int y, int m, int day) => DateTime.utc(y, m, day);

void main() {
  late AppDatabase db;
  late ProviderContainer container;
  final today = d(2026, 10, 14); // a Wednesday

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      todayProvider.overrideWithValue(today),
    ]);
  });
  tearDown(() async {
    container.dispose();
    await db.close();
  });

  PlanRepository plan() => container.read(planRepositoryProvider);

  Future<void> openAccount(int balance) =>
      db.into(db.accounts).insert(AccountsCompanion.insert(kind: AccountKind.bank, name: 'Bank', openingBalance: Value(balance), color: 0xFF4A5866));

  /// Keeps every input subscribed, waits until each stream has delivered,
  /// then reads [provider].
  Future<T> settle<T>(ProviderListenable<T> provider) async {
    final inputs = [balanceProvider, settingsProvider, rulesProvider, recurringProvider, eventsProvider, goalsProvider, recentEntriesProvider, categoriesProvider];
    for (final p in inputs) {
      container.listen(p, (_, _) {});
    }
    container.listen(provider, (_, _) {});
    for (var i = 0; i < 50 && inputs.any((p) => container.read(p).isLoading); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    return container.read(provider);
  }

  test('projection is null before setup', () async {
    container.listen(projectionProvider, (_, _) {});
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(container.read(projectionProvider), isNull);
  });

  test('projection uses the stored balance, rhythm, bills and goal', () async {
    await openAccount(100000);
    await plan().saveSettings(PlanSettings(openingDate: today, weeklyCap: 5000, buffer: 10000));
    await plan().saveRule(const WeeklyRule(weekday: 3, label: 'Weekday', type: DayType.spend, plannedSpend: 1000));
    await plan().addRecurring(name: 'Rent', isIncome: false, amount: 30000, categoryKey: 'bills', nextDue: d(2026, 10, 16));
    await plan().addGoal(name: 'Laptop', price: 50000, targetDate: d(2026, 10, 17));

    final p = await settle(projectionProvider);
    // 14/10: −RM10 (Wednesday plan). 16/10: −RM300 rent. 17/10: −RM500 laptop.
    expect(p!.goals.single.leftAfterBuying, 100000 - 1000 - 30000 - 50000);
    expect(p.goals.single.onTrack, isTrue);
  });

  test('spending logged today reduces what the projection still subtracts', () async {
    await openAccount(100000);
    await plan().saveSettings(PlanSettings(openingDate: today, weeklyCap: 5000, buffer: 0));
    await plan().saveRule(const WeeklyRule(weekday: 3, label: 'Weekday', type: DayType.spend, plannedSpend: 1000));
    await plan().addGoal(name: 'Laptop', price: 10000, targetDate: today);
    await container
        .read(ledgerRepositoryProvider)
        .add(EntryDraft(day: today, isIncome: false, amount: 400, categoryKey: 'food'));

    final p = await settle(projectionProvider);
    // Balance is already −RM4; only the remaining RM6 of today's plan applies.
    expect(p!.goals.single.leftAfterBuying, 100000 - 400 - 600 - 10000);
    expect(await settle(weekSpentProvider), 400);
  });

  test('confirming a recurring item logs it and moves it to next month', () async {
    await openAccount(100000);
    await plan().saveSettings(PlanSettings(openingDate: d(2026, 10, 1), weeklyCap: 5000, buffer: 0));
    final id = await plan().addRecurring(name: 'Internet', isIncome: false, amount: 12900, categoryKey: 'bills', nextDue: d(2026, 10, 10));

    expect((await settle(dueRecurringProvider)).map((r) => r.id), [id]);
    await plan().confirmRecurring(id, due: d(2026, 10, 10), paidOn: today);

    final item = (await plan().watchRecurring().first).single;
    expect(item.nextDue, d(2026, 11, 10));
    final logged = (await container.read(ledgerRepositoryProvider).watchSince(today).first).single;
    expect((logged.amount, logged.label, logged.categoryKey), (12900, 'Internet', 'bills'));
    expect(await container.read(ledgerRepositoryProvider).watchBalance().first, 100000 - 12900);
  });

  test('today rule follows the weekday', () async {
    await plan().saveRule(const WeeklyRule(weekday: 3, label: 'Midweek', type: DayType.flex, plannedSpend: 500));
    expect((await settle(todayRuleProvider))!.label, 'Midweek');
  });

  test('a paused recurring item is neither due nor projected', () async {
    await openAccount(100000);
    await plan().saveSettings(PlanSettings(openingDate: d(2026, 10, 1), weeklyCap: 5000, buffer: 0));
    final id = await plan().addRecurring(name: 'Gym', isIncome: false, amount: 9000, categoryKey: 'bills', nextDue: d(2026, 10, 10));
    await plan().addGoal(name: 'Laptop', price: 10000, targetDate: d(2026, 11, 30));
    await plan().setRecurringActive(id, active: false);

    expect(await settle(dueRecurringProvider), isEmpty);
    expect((await settle(projectionProvider))!.goals.single.leftAfterBuying, 100000 - 10000);
    expect((await plan().watchRecurring().first).single.active, isFalse);
  });

  test('marking a goal bought logs it and removes it from the active goals', () async {
    await openAccount(100000);
    await plan().saveSettings(PlanSettings(openingDate: d(2026, 10, 1), weeklyCap: 5000, buffer: 0));
    final id = await plan().addGoal(name: 'Laptop', price: 45000, targetDate: d(2026, 12, 1));
    await plan().markGoalBought(id, on: today);

    expect(await plan().watchActiveGoals().first, isEmpty);
    final e = (await container.read(ledgerRepositoryProvider).watchSince(today).first).single;
    expect((e.amount, e.label, e.isIncome), (45000, 'Laptop', false));
    final row = await (db.select(db.goals)..where((g) => g.id.equals(id))).getSingle();
    expect((row.status, row.achievedOn), (GoalStatus.achieved, today));
  });

  test('a finished event stops counting in the projection', () async {
    await openAccount(100000);
    await plan().saveSettings(PlanSettings(openingDate: d(2026, 10, 1), weeklyCap: 5000, buffer: 0));
    final id = await plan().addEvent(name: 'Car service', isIncome: false, amount: 25000, categoryKey: 'transport', date: d(2026, 10, 20));
    await plan().addGoal(name: 'Laptop', price: 10000, targetDate: d(2026, 10, 31));
    expect((await settle(projectionProvider))!.goals.single.leftAfterBuying, 100000 - 25000 - 10000);

    await plan().setEventDone(id, date: d(2026, 10, 20), done: true);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(container.read(projectionProvider)!.goals.single.leftAfterBuying, 100000 - 10000);
  });
}
