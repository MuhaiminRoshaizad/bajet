import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables.dart';

export 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [AppSettings, Categories, Entries, WeeklyRules, RecurringItems, PlannedEvents, Goals, Favourites],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? driftDatabase(name: 'bajet'));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _seedDefaults();
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  /// Starting values a new install needs before the owner edits them. They
  /// are deliberately generic; balances, bills, goals and favourites come from
  /// setup or a backup import.
  Future<void> _seedDefaults() async {
    await batch((b) {
      b.insertAll(categories, [
        for (final (i, c) in _defaultCategories.indexed)
          CategoriesCompanion.insert(
            key: c.$1,
            label: c.$2,
            kind: c.$3,
            tint: c.$4,
            isFixed: Value(c.$5),
            sortOrder: Value(i),
          ),
      ]);
      b.insertAll(weeklyRules, [
        for (var weekday = 1; weekday <= 7; weekday++)
          WeeklyRulesCompanion.insert(
            weekday: Value(weekday),
            label: weekday <= 5 ? 'Weekday' : 'Weekend',
            dayType: RhythmDayType.spend,
          ),
      ]);
    });
  }
}

const _defaultCategories = [
  ('food', 'Food', EntryKind.expense, 'apricot', false),
  ('transport', 'Transport', EntryKind.expense, 'sky', false),
  ('pets', 'Pets', EntryKind.expense, 'sage', false),
  ('family', 'Family', EntryKind.expense, 'rose', false),
  ('gifts', 'Gifts', EntryKind.expense, 'pink', false),
  ('bills', 'Bills', EntryKind.expense, 'teal', true),
  ('personal', 'Personal', EntryKind.expense, 'olive', false),
  ('other', 'Other', EntryKind.expense, 'neutral', false),
  ('goal', 'Goals', EntryKind.expense, 'apricot', true),
  ('salary', 'Salary', EntryKind.income, 'sage', true),
  ('kwsp', 'KWSP', EntryKind.income, 'teal', true),
  ('refund', 'Refund', EntryKind.income, 'sky', false),
  ('other_income', 'Other', EntryKind.income, 'neutral', false),
];
