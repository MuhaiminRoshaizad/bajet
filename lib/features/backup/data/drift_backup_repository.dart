import 'package:drift/drift.dart';
import 'package:drift/native.dart' show SqliteException;

import '../../../core/database/app_database.dart';
import '../domain/backup_repository.dart';

const _day = DayConverter();

/// Writes and reads the backup format by hand, table by table, so the file
/// stays stable and readable whatever drift does internally.
class DriftBackupRepository implements BackupRepository {
  DriftBackupRepository(this._db);

  final AppDatabase _db;

  @override
  Future<Map<String, Object?>> export() async {
    final settings = await _db.select(_db.appSettings).getSingleOrNull();
    return {
      'app': 'bajet',
      'format': backupFormatVersion,
      'settings': settings == null
          ? null
          : {
              'openingDate': _day.toSql(settings.openingDate),
              'weeklyCap': settings.weeklyCap,
              'buffer': settings.buffer,
              'totalCardColor': settings.totalCardColor,
              'totalCardFinish': settings.totalCardFinish.name,
            },
      'accounts': [
        for (final a in await _db.select(_db.accounts).get())
          {
            'id': a.id,
            'kind': a.kind.name,
            'name': a.name,
            'nickname': a.nickname,
            'openingBalance': a.openingBalance,
            'color': a.color,
            'inkColor': a.inkColor,
            'finish': a.finish.name,
            'sortOrder': a.sortOrder,
          },
      ],
      'transfers': [
        for (final t in await _db.select(_db.transfers).get())
          {
            'id': t.id,
            'occurredOn': _day.toSql(t.occurredOn),
            'fromAccountId': t.fromAccountId,
            'toAccountId': t.toAccountId,
            'amount': t.amount,
            'note': t.note,
          },
      ],
      'categories': [
        for (final c in await _db.select(_db.categories).get())
          {
            'key': c.key,
            'label': c.label,
            'kind': c.kind.name,
            'tint': c.tint,
            'isFixed': c.isFixed,
            'monthlyBudget': c.monthlyBudget,
            'archived': c.archived,
            'sortOrder': c.sortOrder,
          },
      ],
      'weeklyRules': [
        for (final r in await _db.select(_db.weeklyRules).get())
          {'weekday': r.weekday, 'label': r.label, 'dayType': r.dayType.name, 'plannedSpend': r.plannedSpend, 'isFastingDay': r.isFastingDay},
      ],
      'recurringItems': [
        for (final r in await _db.select(_db.recurringItems).get())
          {
            'id': r.id,
            'name': r.name,
            'kind': r.kind.name,
            'amount': r.amount,
            'categoryKey': r.categoryKey,
            'nextDue': _day.toSql(r.nextDue),
            'active': r.active,
            'isEstimate': r.isEstimate,
            'windowDays': r.windowDays,
            'accountId': r.accountId,
          },
      ],
      'plannedEvents': [
        for (final e in await _db.select(_db.plannedEvents).get())
          {
            'id': e.id,
            'name': e.name,
            'kind': e.kind.name,
            'amount': e.amount,
            'categoryKey': e.categoryKey,
            'dueOn': _day.toSql(e.dueOn),
            'done': e.done,
            'countInProjection': e.countInProjection,
            'repeatsYearly': e.repeatsYearly,
          },
      ],
      'goals': [
        for (final g in await _db.select(_db.goals).get())
          {
            'id': g.id,
            'name': g.name,
            'price': g.price,
            'targetDate': _day.toSql(g.targetDate),
            'priority': g.priority,
            'listingUrl': g.listingUrl,
            'status': g.status.name,
            'achievedOn': g.achievedOn == null ? null : _day.toSql(g.achievedOn!),
          },
      ],
      'favourites': [
        for (final f in await _db.select(_db.favourites).get())
          {'id': f.id, 'label': f.label, 'categoryKey': f.categoryKey, 'amount': f.amount, 'sortOrder': f.sortOrder},
      ],
      'entries': [
        for (final e in await _db.select(_db.entries).get())
          {
            'id': e.id,
            'occurredOn': _day.toSql(e.occurredOn),
            'kind': e.kind.name,
            'amount': e.amount,
            'categoryKey': e.categoryKey,
            'label': e.label,
            'note': e.note,
            'receipt': e.receipt,
            'recurringItemId': e.recurringItemId,
            'plannedEventId': e.plannedEventId,
            'plannedEventOn': e.plannedEventOn == null ? null : _day.toSql(e.plannedEventOn!),
            'accountId': e.accountId,
          },
      ],
    };
  }

  @override
  Future<void> restore(Map<String, Object?> original) async {
    if (original['app'] != 'bajet') throw const BackupFormatException('This file is not a bajet backup.');
    final backup = upgradeBackup(original);
    try {
      await _db.transaction(() async {
        // Children before parents, so foreign keys never point at nothing.
        for (final TableInfo<Table, Object?> t in [
          _db.entries,
          _db.favourites,
          _db.transfers,
          _db.recurringItems,
          _db.plannedEvents,
          _db.goals,
          _db.weeklyRules,
          _db.accounts,
          _db.categories,
          _db.appSettings,
        ]) {
          await _db.delete(t).go();
        }
        final s = backup['settings'] as Map<String, Object?>?;
        if (s != null) {
          await _db.into(_db.appSettings).insert(AppSettingsCompanion.insert(
                openingDate: _day.fromSql(s['openingDate']! as String),
                weeklyCap: s['weeklyCap']! as int,
                buffer: s['buffer']! as int,
                totalCardColor: Value(s['totalCardColor'] as int?),
                totalCardFinish: Value(CardFinish.values.byName(s['totalCardFinish']! as String)),
              ));
        }
        await _db.batch((b) {
          b.insertAll(_db.accounts, [
            for (final a in _list(backup, 'accounts'))
              AccountsCompanion.insert(
                id: Value(a['id']! as int),
                kind: AccountKind.values.byName(a['kind']! as String),
                name: a['name']! as String,
                nickname: Value(a['nickname'] as String?),
                openingBalance: Value(a['openingBalance']! as int),
                color: a['color']! as int,
                inkColor: Value(a['inkColor'] as int?),
                finish: Value(CardFinish.values.byName(a['finish']! as String)),
                sortOrder: Value(a['sortOrder']! as int),
              ),
          ]);
          b.insertAll(_db.transfers, [
            for (final t in _list(backup, 'transfers'))
              TransfersCompanion.insert(
                id: Value(t['id']! as int),
                occurredOn: _day.fromSql(t['occurredOn']! as String),
                fromAccountId: t['fromAccountId']! as int,
                toAccountId: t['toAccountId']! as int,
                amount: t['amount']! as int,
                note: Value(t['note'] as String?),
              ),
          ]);
          b.insertAll(_db.categories, [
            for (final c in _list(backup, 'categories'))
              CategoriesCompanion.insert(
                key: c['key']! as String,
                label: c['label']! as String,
                kind: EntryKind.values.byName(c['kind']! as String),
                tint: c['tint']! as String,
                isFixed: Value(c['isFixed']! as bool),
                monthlyBudget: Value(c['monthlyBudget'] as int?),
                archived: Value(c['archived']! as bool),
                sortOrder: Value(c['sortOrder']! as int),
              ),
          ]);
          b.insertAll(_db.weeklyRules, [
            for (final r in _list(backup, 'weeklyRules'))
              WeeklyRulesCompanion.insert(
                weekday: Value(r['weekday']! as int),
                label: r['label']! as String,
                dayType: RhythmDayType.values.byName(r['dayType']! as String),
                plannedSpend: Value(r['plannedSpend']! as int),
                isFastingDay: Value(r['isFastingDay']! as bool),
              ),
          ]);
          b.insertAll(_db.recurringItems, [
            for (final r in _list(backup, 'recurringItems'))
              RecurringItemsCompanion.insert(
                id: Value(r['id']! as int),
                name: r['name']! as String,
                kind: EntryKind.values.byName(r['kind']! as String),
                amount: r['amount']! as int,
                categoryKey: r['categoryKey']! as String,
                nextDue: _day.fromSql(r['nextDue']! as String),
                active: Value(r['active']! as bool),
                isEstimate: Value(r['isEstimate']! as bool),
                windowDays: Value(r['windowDays']! as int),
                accountId: r['accountId']! as int,
              ),
          ]);
          b.insertAll(_db.plannedEvents, [
            for (final e in _list(backup, 'plannedEvents'))
              PlannedEventsCompanion.insert(
                id: Value(e['id']! as int),
                name: e['name']! as String,
                kind: EntryKind.values.byName(e['kind']! as String),
                amount: e['amount']! as int,
                categoryKey: e['categoryKey']! as String,
                dueOn: _day.fromSql(e['dueOn']! as String),
                done: Value(e['done']! as bool),
                countInProjection: Value(e['countInProjection']! as bool),
                repeatsYearly: Value(e['repeatsYearly']! as bool),
              ),
          ]);
          b.insertAll(_db.goals, [
            for (final g in _list(backup, 'goals'))
              GoalsCompanion.insert(
                id: Value(g['id']! as int),
                name: g['name']! as String,
                price: g['price']! as int,
                targetDate: _day.fromSql(g['targetDate']! as String),
                priority: Value(g['priority']! as int),
                listingUrl: Value(g['listingUrl'] as String?),
                status: Value(GoalStatus.values.byName(g['status']! as String)),
                achievedOn: Value(g['achievedOn'] == null ? null : _day.fromSql(g['achievedOn']! as String)),
              ),
          ]);
          b.insertAll(_db.favourites, [
            for (final f in _list(backup, 'favourites'))
              FavouritesCompanion.insert(
                id: Value(f['id']! as int),
                label: f['label']! as String,
                categoryKey: f['categoryKey']! as String,
                amount: f['amount']! as int,
                sortOrder: Value(f['sortOrder']! as int),
              ),
          ]);
          b.insertAll(_db.entries, [
            for (final e in _list(backup, 'entries'))
              EntriesCompanion.insert(
                id: Value(e['id']! as int),
                occurredOn: _day.fromSql(e['occurredOn']! as String),
                kind: EntryKind.values.byName(e['kind']! as String),
                amount: e['amount']! as int,
                categoryKey: e['categoryKey']! as String,
                label: Value(e['label'] as String?),
                note: Value(e['note'] as String?),
                receipt: Value(e['receipt'] as String?),
                recurringItemId: Value(e['recurringItemId'] as int?),
                plannedEventId: Value(e['plannedEventId'] as int?),
                plannedEventOn: Value(e['plannedEventOn'] == null ? null : _day.fromSql(e['plannedEventOn']! as String)),
                accountId: e['accountId']! as int,
              ),
          ]);
        });
        // Older backups predate some built-in categories; add them back.
        await _db.ensureBuiltInCategories();
      });
    } on TypeError {
      throw const BackupFormatException('This backup is damaged or incomplete.');
    } on ArgumentError {
      throw const BackupFormatException('This backup contains values bajet does not recognise.');
    } on SqliteException {
      // Rows of the right shape that break the database's own rules, such as
      // an amount of zero or a category that does not exist.
      throw const BackupFormatException('This backup is damaged or incomplete.');
    }
  }

  static List<Map<String, Object?>> _list(Map<String, Object?> backup, String key) =>
      [for (final item in (backup[key] as List<Object?>? ?? const [])) item! as Map<String, Object?>];
}
