import 'package:bajet/core/database/app_database.dart';
import 'package:bajet/features/ledger/data/drift_ledger_repository.dart';
import 'package:bajet/features/ledger/domain/ledger_models.dart' as domain;
import 'package:bajet/features/plan/data/drift_plan_repository.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

DateTime d(int y, int m, int day) => DateTime.utc(y, m, day);

void main() {
  late AppDatabase db;
  late DriftLedgerRepository ledger;
  late DriftFavouriteRepository favourites;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    ledger = DriftLedgerRepository(db);
    favourites = DriftFavouriteRepository(db);
    // Every entry belongs to an account; this first one starts empty.
    await db.into(db.accounts).insert(AccountsCompanion.insert(kind: AccountKind.bank, name: 'Bank', color: 0xFF4A5866));
  });
  tearDown(() => db.close());

  Future<int> openAccount(int balance, {String name = 'Bank'}) =>
      db.into(db.accounts).insert(AccountsCompanion.insert(kind: AccountKind.bank, name: name, openingBalance: Value(balance), color: 0xFF4A5866));

  Future<void> setUpOpening(int balance, DateTime day) async {
    await db.into(db.appSettings).insert(AppSettingsCompanion.insert(openingDate: day, weeklyCap: 5000, buffer: 50000));
    await (db.update(db.accounts)..where((a) => a.id.equals(1))).write(AccountsCompanion(openingBalance: Value(balance)));
  }

  domain.EntryDraft spend(DateTime day, int amount, {String category = 'food', String? label}) =>
      domain.EntryDraft(day: day, isIncome: false, amount: amount, categoryKey: category, label: label);

  test('balance is null before setup stores an opening balance', () async {
    expect(await ledger.watchBalance().first, isNull);
  });

  test('balance is the opening balance plus entries from the opening date on', () async {
    await setUpOpening(100000, d(2026, 7, 1));
    await ledger.add(spend(d(2026, 6, 30), 9999)); // before opening: ignored
    await ledger.add(spend(d(2026, 7, 1), 1250));
    await ledger.add(domain.EntryDraft(day: d(2026, 7, 2), isIncome: true, amount: 5000, categoryKey: 'refund'));
    expect(await ledger.watchBalance().first, 100000 - 1250 + 5000);
  });

  test('watchSince returns entries from the day on, newest first', () async {
    await ledger.add(spend(d(2026, 7, 1), 100));
    await ledger.add(spend(d(2026, 7, 3), 300));
    await ledger.add(spend(d(2026, 7, 2), 200));
    final list = await ledger.watchSince(d(2026, 7, 2)).first;
    expect(list.map((e) => e.amount), [300, 200]);
  });

  test('blank labels and notes are stored as null', () async {
    await ledger.add(domain.EntryDraft(day: d(2026, 7, 1), isIncome: false, amount: 100, categoryKey: 'food', label: '  ', note: ''));
    final e = (await ledger.watchSince(d(2026, 7, 1)).first).single;
    expect(e.label, isNull);
    expect(e.note, isNull);
  });

  test('restore puts a deleted entry back with its id', () async {
    final id = await ledger.add(spend(d(2026, 7, 1), 450, label: 'Coffee'));
    final entry = (await ledger.watchSince(d(2026, 7, 1)).first).single;
    await ledger.delete(id);
    expect(await ledger.watchSince(d(2026, 7, 1)).first, isEmpty);
    await ledger.restore(entry);
    final back = (await ledger.watchSince(d(2026, 7, 1)).first).single;
    expect((back.id, back.amount, back.label), (id, 450, 'Coffee'));
  });

  test('update changes amount and category', () async {
    final id = await ledger.add(spend(d(2026, 7, 1), 450));
    await ledger.update(domain.Entry(id: id, day: d(2026, 7, 1), isIncome: false, amount: 600, categoryKey: 'transport'));
    final e = (await ledger.watchSince(d(2026, 7, 1)).first).single;
    expect((e.amount, e.categoryKey), (600, 'transport'));
  });

  test('categories exclude archived ones and keep their order', () async {
    await (db.update(db.categories)..where((c) => c.key.equals('pets'))).write(const CategoriesCompanion(archived: Value(true)));
    final keys = (await ledger.watchCategories().first).map((c) => c.key);
    expect(keys.first, 'food');
    expect(keys, isNot(contains('pets')));
  });

  test('favourites can be added, edited and removed', () async {
    final id = await favourites.add(label: ' Coffee ', categoryKey: 'food', amount: 450);
    expect((await favourites.watchAll().first).single.label, 'Coffee');
    await favourites.update(domain.Favourite(id: id, label: 'Tea', categoryKey: 'food', amount: 300));
    expect((await favourites.watchAll().first).single.amount, 300);
    await favourites.delete(id);
    expect(await favourites.watchAll().first, isEmpty);
  });

  test('flexibleSpent leaves out income, fixed categories, bills and other days', () {
    final entries = [
      domain.Entry(id: 5, day: d(2026, 7, 8), isIncome: false, amount: 1500, categoryKey: 'pets', billId: 2),
      domain.Entry(id: 1, day: d(2026, 7, 6), isIncome: false, amount: 1000, categoryKey: 'food'),
      domain.Entry(id: 2, day: d(2026, 7, 7), isIncome: false, amount: 5000, categoryKey: 'bills'),
      domain.Entry(id: 3, day: d(2026, 7, 7), isIncome: true, amount: 9000, categoryKey: 'refund'),
      domain.Entry(id: 4, day: d(2026, 7, 13), isIncome: false, amount: 700, categoryKey: 'food'),
    ];
    expect(domain.flexibleSpent(entries, {'bills'}, d(2026, 7, 6), d(2026, 7, 12)), 1000);
  });

  test('weekStart is the Monday of the week', () {
    expect(domain.weekStart(d(2026, 7, 1)), d(2026, 6, 29));
    expect(domain.weekStart(d(2026, 6, 29)), d(2026, 6, 29));
    expect(domain.weekStart(d(2026, 7, 5)), d(2026, 6, 29));
  });

  test('the balance is every account together, and moving money between them leaves it alone', () async {
    await setUpOpening(100000, d(2026, 7, 1));
    final cash = await openAccount(5000, name: 'Cash');
    await ledger.add(domain.EntryDraft(day: d(2026, 7, 2), isIncome: false, amount: 700, categoryKey: 'food', accountId: cash));
    expect(await ledger.watchBalance().first, 104300);

    await db.into(db.transfers).insert(TransfersCompanion.insert(occurredOn: d(2026, 7, 3), fromAccountId: 1, toAccountId: cash, amount: 20000));
    expect(await ledger.watchBalance().first, 104300);
  });

  test('an entry goes to the account it names, or else to the first one', () async {
    await setUpOpening(100000, d(2026, 7, 1));
    final cash = await openAccount(5000, name: 'Cash');
    await ledger.add(spend(d(2026, 7, 2), 450));
    await ledger.add(domain.EntryDraft(day: d(2026, 7, 2), isIncome: false, amount: 700, categoryKey: 'food', accountId: cash));
    final entries = await ledger.watchSince(d(2026, 7, 1)).first;
    expect({for (final e in entries) e.amount: e.accountId}, {450: 1, 700: cash});
  });

  test('an entry for a bill settles its month at the amount logged, and deleting the latest takes it back', () async {
    final plan = DriftPlanRepository(db);
    final gaji = await plan.addRecurring(name: 'Gaji', isIncome: true, amount: 238445, categoryKey: 'salary', nextDue: d(2026, 11, 1));
    Future<DateTime> due() async => (await plan.watchRecurring().first).single.nextDue;

    final november = await ledger.add(domain.EntryDraft(day: d(2026, 11, 3), isIncome: true, amount: 261230, categoryKey: 'salary', label: 'Gaji', billId: gaji));
    expect(await due(), d(2026, 12, 1));
    final logged = (await ledger.watchSince(d(2000, 1, 1)).first).single;
    expect((logged.amount, logged.day, logged.billId), (261230, d(2026, 11, 3), gaji));

    final december = await ledger.add(domain.EntryDraft(day: d(2026, 12, 1), isIncome: true, amount: 238445, categoryKey: 'salary', billId: gaji));
    await ledger.delete(november);
    expect(await due(), d(2027, 1, 1), reason: 'an older payment going leaves the later one standing');

    final gone = (await ledger.watchSince(d(2000, 1, 1)).first).single;
    await ledger.delete(december);
    expect(await due(), d(2026, 12, 1));
    await ledger.restore(gone);
    expect(await due(), d(2027, 1, 1), reason: 'Undo settles it again');
  });

  test('an entry for an income event closes it at the real amount, and a yearly one moves on a year', () async {
    final plan = DriftPlanRepository(db);
    final kwsp = await plan.addEvent(name: 'KWSP cash out', isIncome: true, amount: 30000, categoryKey: 'kwsp', date: d(2026, 12, 15));
    final bonus = await plan.addEvent(name: 'Bonus', isIncome: true, amount: 100000, categoryKey: 'salary', date: d(2026, 12, 20), repeatsYearly: true);
    final got = await ledger.add(domain.EntryDraft(day: d(2026, 12, 15), isIncome: true, amount: 35000, categoryKey: 'kwsp', event: domain.EventLink(kwsp, d(2026, 12, 15))));
    await ledger.add(domain.EntryDraft(day: d(2026, 12, 20), isIncome: true, amount: 90000, categoryKey: 'salary', event: domain.EventLink(bonus, d(2026, 12, 20))));
    final events = {for (final e in await plan.watchEvents().first) e.name: e};
    expect(events['KWSP cash out']!.done, isTrue);
    expect((events['Bonus']!.done, events['Bonus']!.date), (false, d(2027, 12, 20)));

    await ledger.delete(got);
    expect((await plan.watchEvents().first).firstWhere((e) => e.id == kwsp).done, isFalse, reason: 'taking the money back opens it again');
  });

  test('spending for an expense event leaves the event open, as before', () async {
    final plan = DriftPlanRepository(db);
    final trip = await plan.addEvent(name: 'Trip', isIncome: false, amount: 50000, categoryKey: 'other', date: d(2026, 12, 1));
    await ledger.add(domain.EntryDraft(day: d(2026, 12, 1), isIncome: false, amount: 20000, categoryKey: 'other', event: domain.EventLink(trip, d(2026, 12, 1))));
    final e = (await plan.watchEvents().first).single;
    expect((e.done, e.spent), (false, 20000));
  });
}
