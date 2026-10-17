import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../../features/accounts/domain/account_models.dart' show firstAccountColor, firstAccountName;
import '../../features/plan/domain/plan_models.dart' show maxWindowDays;
import 'tables.dart';

export 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [AppSettings, Accounts, Transfers, Categories, Entries, WeeklyRules, RecurringItems, PlannedEvents, Goals, Favourites],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? driftDatabase(name: 'bajet'));

  @override
  int get schemaVersion => 7;

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
          if (from < 4) await m.addColumn(plannedEvents, plannedEvents.repeatsYearly);
          if (from < 5) {
            await m.addColumn(entries, entries.plannedEventId);
            await m.addColumn(entries, entries.plannedEventOn);
          }
          if (from < 6) await _moveToAccounts(m);
          if (from < 7) await _retireBrushedMetal(m);
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
          await ensureBuiltInCategories();
        },
      );

  /// Version 6 keeps money in accounts. The one starting balance becomes the
  /// first account's, and every entry and bill so far belongs to it; the
  /// user names it and adds the others afterwards.
  Future<void> _moveToAccounts(Migrator m) async {
    await m.createTable(accounts);
    await m.createTable(transfers);
    final opening = await customSelect('SELECT opening_balance FROM app_settings').getSingleOrNull();
    await into(accounts).insert(AccountsCompanion.insert(
      id: const Value(1),
      kind: AccountKind.bank,
      name: firstAccountName,
      openingBalance: Value(opening?.read<int>('opening_balance') ?? 0),
      color: firstAccountColor,
    ));
    await m.alterTable(TableMigration(entries, newColumns: [entries.accountId], columnTransformer: {entries.accountId: const Constant(1)}));
    await m.alterTable(TableMigration(recurringItems, newColumns: [recurringItems.accountId], columnTransformer: {recurringItems.accountId: const Constant(1)}));
    await m.alterTable(TableMigration(appSettings, newColumns: [appSettings.totalCardColor, appSettings.totalCardFinish]));
  }

  /// Version 7 drops the brushed metal finish: every card and the total card
  /// that had it turns matte, which is also the new default.
  Future<void> _retireBrushedMetal(Migrator m) async {
    const matte = "CASE WHEN {c} = 'brushed' THEN 'matte' ELSE {c} END";
    await m.alterTable(TableMigration(accounts, columnTransformer: {accounts.finish: CustomExpression<String>(matte.replaceAll('{c}', 'finish'))}));
    await m.alterTable(TableMigration(
      appSettings,
      columnTransformer: {appSettings.totalCardFinish: CustomExpression<String>(matte.replaceAll('{c}', 'total_card_finish'))},
    ));
  }

  /// [id], or when none is named the first account in order. Throws before
  /// setup has added an account, since nothing can be logged then.
  Future<int> accountOrFirst(int? id) async {
    if (id != null) return id;
    final q = select(accounts)
      ..orderBy([(a) => OrderingTerm(expression: a.sortOrder), (a) => OrderingTerm(expression: a.id)])
      ..limit(1);
    final first = await q.getSingleOrNull();
    if (first == null) throw StateError('No account yet: setup has not been finished.');
    return first.id;
  }

  /// The categories the app logs into itself, which the user never picks:
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

  /// Starting values a new install needs before the user edits them. They
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
