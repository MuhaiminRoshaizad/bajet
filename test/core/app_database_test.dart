import 'package:bajet/core/database/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('a new database starts with generic categories and a blank rhythm', () async {
    final cats = await db.select(db.categories).get();
    expect(cats.where((c) => c.kind == EntryKind.expense), hasLength(9));
    expect(cats.where((c) => c.kind == EntryKind.income), hasLength(4));

    final rules = await db.select(db.weeklyRules).get();
    expect(rules.map((r) => r.weekday), [1, 2, 3, 4, 5, 6, 7]);
    expect(rules.every((r) => r.plannedSpend == 0 && !r.isFastingDay), isTrue);

    expect(await db.select(db.favourites).get(), isEmpty);
    expect(await db.select(db.appSettings).getSingleOrNull(), isNull);
  });

  test('stores calendar days as ISO text and reads them back unchanged', () async {
    final day = DateTime.utc(2026, 7, 1);
    await db.into(db.entries).insert(
          EntriesCompanion.insert(occurredOn: day, kind: EntryKind.expense, amount: 450, categoryKey: 'food'),
        );
    final raw = await db.customSelect('SELECT occurred_on FROM entries').getSingle();
    expect(raw.read<String>('occurred_on'), '2026-07-01');
    expect((await db.select(db.entries).getSingle()).occurredOn, day);
  });

  test('rejects an amount of zero', () async {
    final insert = db.into(db.entries).insert(
          EntriesCompanion.insert(occurredOn: DateTime.utc(2026, 7, 1), kind: EntryKind.expense, amount: 0, categoryKey: 'food'),
        );
    expect(insert, throwsA(isA<SqliteException>()));
  });

  test('rejects an entry in a category that does not exist', () async {
    final insert = db.into(db.entries).insert(
          EntriesCompanion.insert(occurredOn: DateTime.utc(2026, 7, 1), kind: EntryKind.expense, amount: 100, categoryKey: 'nope'),
        );
    expect(insert, throwsA(isA<SqliteException>()));
  });

  test('keeps the generated schema in step with the declared version', () {
    expect(db.schemaVersion, 1);
    expect(db.allTables.map((t) => t.actualTableName), containsAll(['entries', 'categories', 'weekly_rules', 'goals']));
  });
}

