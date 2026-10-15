import 'dart:io';

import 'package:bajet/core/database/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('a new database starts with generic categories and a blank rhythm', () async {
    final cats = await db.select(db.categories).get();
    expect(cats.where((c) => c.kind == EntryKind.expense), hasLength(10));
    expect(cats.where((c) => c.kind == EntryKind.income), hasLength(4));

    final rules = await db.select(db.weeklyRules).get();
    expect(rules.map((r) => r.weekday), [1, 2, 3, 4, 5, 6, 7]);
    expect(rules.every((r) => r.plannedSpend == 0 && !r.isFastingDay), isTrue);

    expect(await db.select(db.favourites).get(), isEmpty);
    expect(await db.select(db.appSettings).getSingleOrNull(), isNull);
  });

  test('built-in categories come back if missing, and nothing is duplicated', () async {
    await (db.delete(db.categories)..where((c) => c.key.equals('untracked'))).go();
    await db.ensureBuiltInCategories();
    await db.ensureBuiltInCategories();
    final untracked = await (db.select(db.categories)..where((c) => c.key.equals('untracked'))).get();
    expect(untracked.single.isFixed, isTrue);
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
    expect(db.schemaVersion, 5);
    expect(db.allTables.map((t) => t.actualTableName), containsAll(['entries', 'categories', 'weekly_rules', 'goals']));
  });

  test('a version 1 database gains the receipt column and keeps its entries', () async {
    final old = AppDatabase(NativeDatabase.memory(setup: (raw) {
      raw.execute(File('test/core/fixtures/schema_v1.sql').readAsStringSync());
      raw.execute("INSERT INTO categories (key, label, kind, tint) VALUES ('food', 'Food', 'expense', 'apricot')");
      raw.execute("INSERT INTO entries (occurred_on, kind, amount, category_key) VALUES ('2026-07-01', 'expense', 450, 'food')");
      raw.execute('PRAGMA user_version = 1');
    }));
    addTearDown(old.close);
    final entry = await old.select(old.entries).getSingle();
    expect((entry.amount, entry.receipt), (450, null));
  });

  test('a version 2 database gains the window column and keeps its bills', () async {
    final old = AppDatabase(NativeDatabase.memory(setup: (raw) {
      raw.execute(File('test/core/fixtures/schema_v2.sql').readAsStringSync());
      raw.execute("INSERT INTO categories (key, label, kind, tint) VALUES ('bills', 'Bills', 'expense', 'sky')");
      raw.execute("INSERT INTO recurring_items (name, kind, amount, category_key, next_due) VALUES ('Rent', 'expense', 50000, 'bills', '2026-08-01')");
      raw.execute('PRAGMA user_version = 2');
    }));
    addTearDown(old.close);
    final rent = await old.select(old.recurringItems).getSingle();
    expect((rent.name, rent.windowDays), ('Rent', 0));
  });

  test('a version 3 database gains the yearly flag and keeps its events', () async {
    final old = AppDatabase(NativeDatabase.memory(setup: (raw) {
      raw.execute(File('test/core/fixtures/schema_v3.sql').readAsStringSync());
      raw.execute("INSERT INTO categories (key, label, kind, tint) VALUES ('gifts', 'Gifts', 'expense', 'pink')");
      raw.execute("INSERT INTO planned_events (name, kind, amount, category_key, due_on) VALUES ('Birthday', 'expense', 10000, 'gifts', '2026-10-30')");
      raw.execute('PRAGMA user_version = 3');
    }));
    addTearDown(old.close);
    final e = await old.select(old.plannedEvents).getSingle();
    expect((e.name, e.repeatsYearly), ('Birthday', false));
  });

  test('a version 4 database gains the event link on entries and keeps them', () async {
    final old = AppDatabase(NativeDatabase.memory(setup: (raw) {
      raw.execute(File('test/core/fixtures/schema_v4.sql').readAsStringSync());
      raw.execute("INSERT INTO categories (key, label, kind, tint) VALUES ('food', 'Food', 'expense', 'apricot')");
      raw.execute("INSERT INTO entries (occurred_on, kind, amount, category_key) VALUES ('2026-07-01', 'expense', 450, 'food')");
      raw.execute('PRAGMA user_version = 4');
    }));
    addTearDown(old.close);
    final entry = await old.select(old.entries).getSingle();
    expect((entry.amount, entry.plannedEventId, entry.plannedEventOn), (450, null, null));
  });
}
