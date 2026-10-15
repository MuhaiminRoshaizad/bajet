import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../../features/plan/domain/plan_models.dart' show maxWindowDays;
import 'tables.dart';

export 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [AppSettings, Categories, Entries, WeeklyRules, RecurringItems, PlannedEvents, Goals, Favourites],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? driftDatabase(name: 'bajet'));

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _seedDefaults();
        },
        // One step per version, so any older database climbs to the latest.
        onUpgrade: (m, from, to) async {
          if (from < 2) await m.addColumn(entries, entries.receipt);
          if (from < 3) await m.addColumn(recurringItems, recurringItems.windowDays);
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
          await ensureBuiltInCategories();
        },
      );

  /// The categories the app logs into itself, which the owner never picks:
  /// goal purchases and money found missing at a check-in. Added if absent,
  /// so older installs and older backups gain any added since.
  Future<void> ensureBuiltInCategories() => batch((b) {
        for (final (i, c) in _defaultCategories.indexed.where((e) => _builtIn.contains(e.$2.$1))) {
          b.insert(
            categories,
            CategoriesCompanion.insert(key: c.$1, label: c.$2, kind: c.$3, tint: c.$4, isFixed: Value(c.$5), sortOrder: Value(i)),
            mode: InsertMode.insertOrIgnore,
          );
        }
      });

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

const _builtIn = {'goal', 'untracked'};

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
  ('untracked', 'Untracked', EntryKind.expense, 'neutral', true),
  ('salary', 'Salary', EntryKind.income, 'sage', true),
  ('kwsp', 'KWSP', EntryKind.income, 'teal', true),
  ('refund', 'Refund', EntryKind.income, 'sky', false),
  ('other_income', 'Other', EntryKind.income, 'neutral', false),
];
