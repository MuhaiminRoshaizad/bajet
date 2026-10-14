import 'package:bajet/core/database/app_database.dart';
import 'package:bajet/features/ledger/data/drift_ledger_repository.dart';
import 'package:bajet/features/ledger/domain/ledger_models.dart' as domain;
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

DateTime d(int y, int m, int day) => DateTime.utc(y, m, day);

void main() {
  late AppDatabase db;
  late DriftLedgerRepository ledger;
  late DriftFavouriteRepository favourites;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    ledger = DriftLedgerRepository(db);
    favourites = DriftFavouriteRepository(db);
  });
  tearDown(() => db.close());

  Future<void> setUpOpening(int balance, DateTime day) => db
      .into(db.appSettings)
      .insert(AppSettingsCompanion.insert(openingBalance: balance, openingDate: day, weeklyCap: 5000, buffer: 50000));

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

  test('flexibleSpent leaves out income, fixed categories and other days', () {
    final entries = [
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
}
