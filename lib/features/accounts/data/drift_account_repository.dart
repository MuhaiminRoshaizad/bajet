import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../domain/account_models.dart' as domain;
import '../domain/account_repository.dart';

class DriftAccountRepository implements AccountRepository {
  DriftAccountRepository(this._db);

  final AppDatabase _db;

  // Each balance is summed in SQL from the opening date on, like the total,
  // so the accounts always add up to it. ISO day strings compare as text.
  static const _balances = '''
SELECT a.*, a.opening_balance
  + COALESCE((SELECT SUM(CASE WHEN e.kind = 'income' THEN e.amount ELSE -e.amount END) FROM entries e, app_settings s
      WHERE e.account_id = a.id AND e.occurred_on >= s.opening_date), 0)
  + COALESCE((SELECT SUM(t.amount) FROM transfers t, app_settings s WHERE t.to_account_id = a.id AND t.occurred_on >= s.opening_date), 0)
  - COALESCE((SELECT SUM(t.amount) FROM transfers t, app_settings s WHERE t.from_account_id = a.id AND t.occurred_on >= s.opening_date), 0)
  AS balance
FROM accounts a ORDER BY a.sort_order, a.id''';

  @override
  Stream<List<domain.Account>> watchAccounts() => _db
      .customSelect(_balances, readsFrom: {_db.accounts, _db.entries, _db.transfers, _db.appSettings})
      .watch()
      .map((rows) => [
            for (final r in rows)
              () {
                final a = _db.accounts.map(r.data);
                return domain.Account(
                  id: a.id,
                  kind: domain.AccountKind.values.byName(a.kind.name),
                  name: a.name,
                  nickname: a.nickname,
                  openingBalance: a.openingBalance,
                  balance: r.read<int>('balance'),
                  look: domain.CardLook(color: a.color, ink: a.inkColor, finish: domain.CardFinish.values.byName(a.finish.name)),
                );
              }(),
          ]);

  @override
  Future<int> addAccount(domain.AccountDraft d) async {
    final last = await (_db.selectOnly(_db.accounts)..addColumns([_db.accounts.sortOrder.max()])).getSingle();
    return _db.into(_db.accounts).insert(AccountsCompanion.insert(
          kind: AccountKind.values.byName(d.kind.name),
          name: d.name.trim(),
          nickname: Value(_blankToNull(d.nickname)),
          // Nothing has been logged to a new account, so what it holds now is
          // what it held from the start.
          openingBalance: Value(d.balance),
          color: d.look.color,
          inkColor: Value(d.look.ink),
          finish: Value(CardFinish.values.byName(d.look.finish.name)),
          sortOrder: Value((last.read(_db.accounts.sortOrder.max()) ?? -1) + 1),
        ));
  }

  @override
  Future<void> reorderAccounts(List<int> ids) => _db.transaction(() async {
        for (final (i, id) in ids.indexed) {
          await (_db.update(_db.accounts)..where((t) => t.id.equals(id))).write(AccountsCompanion(sortOrder: Value(i)));
        }
      });

  @override
  Future<void> updateAccount(domain.Account a) async {
    await (_db.update(_db.accounts)..where((t) => t.id.equals(a.id))).write(AccountsCompanion(
          name: Value(a.name.trim()),
          nickname: Value(_blankToNull(a.nickname)),
          color: Value(a.look.color),
          inkColor: Value(a.look.ink),
          finish: Value(CardFinish.values.byName(a.look.finish.name)),
        ));
  }

  @override
  Future<domain.AccountUse> accountUse(int id) async {
    final entries = await (_db.selectOnly(_db.entries)
          ..addColumns([_db.entries.id.count()])
          ..where(_db.entries.accountId.equals(id)))
        .getSingle();
    final transfers = await (_db.selectOnly(_db.transfers)
          ..addColumns([_db.transfers.id.count()])
          ..where(_db.transfers.fromAccountId.equals(id) | _db.transfers.toAccountId.equals(id)))
        .getSingle();
    final bills = await (_db.select(_db.recurringItems)..where((r) => r.accountId.equals(id))).get();
    return domain.AccountUse(
      entries: entries.read(_db.entries.id.count()) ?? 0,
      transfers: transfers.read(_db.transfers.id.count()) ?? 0,
      bills: [for (final b in bills) b.name],
    );
  }

  @override
  Future<domain.AccountRemoval> deleteAccount(int id, {int? moveTo}) => _db.transaction(() async {
        if (moveTo == id) throw ArgumentError.value(moveTo, 'moveTo', 'An account cannot move into itself');
        final all = await watchAccounts().first;
        if (all.length < 2) throw StateError('The last account cannot be deleted: there must be one to log to.');
        final account = all.firstWhere((a) => a.id == id);
        final row = await (_db.select(_db.accounts)..where((a) => a.id.equals(id))).getSingle();
        final target = moveTo == null ? null : await (_db.select(_db.accounts)..where((a) => a.id.equals(moveTo))).getSingle();
        final entries = await (_db.select(_db.entries)..where((e) => e.accountId.equals(id))).get();
        final transfers = await (_db.select(_db.transfers)..where((t) => t.fromAccountId.equals(id) | t.toAccountId.equals(id))).get();
        final bills = await (_db.select(_db.recurringItems)..where((r) => r.accountId.equals(id))).get();
        final billIds = [for (final b in bills) b.id];
        // Other accounts' entries that confirmed one of its bills lose only
        // the link when the bill goes.
        final linked = moveTo != null
            ? const <Entry>[]
            : await (_db.select(_db.entries)..where((e) => e.recurringItemId.isIn(billIds) & e.accountId.equals(id).not())).get();

        if (target != null) {
          await (_db.update(_db.entries)..where((e) => e.accountId.equals(id))).write(EntriesCompanion(accountId: Value(target.id)));
          await (_db.update(_db.recurringItems)..where((r) => r.accountId.equals(id))).write(RecurringItemsCompanion(accountId: Value(target.id)));
          await (_db.delete(_db.transfers)
                ..where((t) => (t.fromAccountId.equals(id) & t.toAccountId.equals(target.id)) | (t.fromAccountId.equals(target.id) & t.toAccountId.equals(id))))
              .go();
          await (_db.update(_db.transfers)..where((t) => t.fromAccountId.equals(id))).write(TransfersCompanion(fromAccountId: Value(target.id)));
          await (_db.update(_db.transfers)..where((t) => t.toAccountId.equals(id))).write(TransfersCompanion(toAccountId: Value(target.id)));
          await (_db.update(_db.accounts)..where((a) => a.id.equals(target.id)))
              .write(AccountsCompanion(openingBalance: Value(target.openingBalance + row.openingBalance)));
        } else {
          await (_db.update(_db.entries)..where((e) => e.id.isIn([for (final e in linked) e.id]))).write(const EntriesCompanion(recurringItemId: Value(null)));
          await (_db.delete(_db.entries)..where((e) => e.accountId.equals(id))).go();
          await (_db.delete(_db.transfers)..where((t) => t.fromAccountId.equals(id) | t.toAccountId.equals(id))).go();
          await (_db.delete(_db.recurringItems)..where((r) => r.accountId.equals(id))).go();
        }
        await (_db.delete(_db.accounts)..where((a) => a.id.equals(id))).go();
        return _DriftAccountRemoval(account, row: row, target: target, entries: [...entries, ...linked], transfers: transfers, bills: bills);
      });

  @override
  Future<void> restoreAccount(domain.AccountRemoval removal) => _db.transaction(() async {
        if (removal is! _DriftAccountRemoval) throw ArgumentError.value(removal, 'removal', 'Not made by this repository');
        // Every row as it was before, in the order the references need.
        await _db.into(_db.accounts).insertOnConflictUpdate(removal.row);
        if (removal.target case final target?) await _db.into(_db.accounts).insertOnConflictUpdate(target);
        for (final b in removal.bills) {
          await _db.into(_db.recurringItems).insertOnConflictUpdate(b);
        }
        for (final e in removal.entries) {
          await _db.into(_db.entries).insertOnConflictUpdate(e);
        }
        for (final t in removal.transfers) {
          await _db.into(_db.transfers).insertOnConflictUpdate(t);
        }
      });

  @override
  Future<void> setOpeningBalance(int accountId, int balance) async {
    await (_db.update(_db.accounts)..where((t) => t.id.equals(accountId))).write(AccountsCompanion(openingBalance: Value(balance)));
  }

  @override
  Future<int> transfer({required int fromId, required int toId, required int amount, required DateTime day, String? note}) =>
      _db.into(_db.transfers).insert(
            TransfersCompanion.insert(occurredOn: day, fromAccountId: fromId, toAccountId: toId, amount: amount, note: Value(_blankToNull(note))),
          );

  @override
  Stream<List<domain.Transfer>> watchTransfers() => (_db.select(_db.transfers)
        ..orderBy([(t) => OrderingTerm.desc(t.occurredOn), (t) => OrderingTerm.desc(t.id)]))
      .watch()
      .map((rows) => [
            for (final t in rows)
              domain.Transfer(id: t.id, day: t.occurredOn, fromId: t.fromAccountId, toId: t.toAccountId, amount: t.amount, note: t.note),
          ]);

  @override
  Future<void> deleteTransfer(int id) => (_db.delete(_db.transfers)..where((t) => t.id.equals(id))).go();

  @override
  Stream<domain.TotalCardLook> watchTotalLook() => _db.select(_db.appSettings).watchSingleOrNull().map((s) => s == null
      ? const domain.TotalCardLook()
      : domain.TotalCardLook(color: s.totalCardColor, finish: domain.CardFinish.values.byName(s.totalCardFinish.name)));

  @override
  Future<void> saveTotalLook(domain.TotalCardLook look) async {
    await _db.update(_db.appSettings).write(AppSettingsCompanion(
          totalCardColor: Value(look.color),
          totalCardFinish: Value(CardFinish.values.byName(look.finish.name)),
        ));
  }
}

/// Every row [DriftAccountRepository.deleteAccount] changed or removed, as
/// it was before.
class _DriftAccountRemoval extends domain.AccountRemoval {
  _DriftAccountRemoval(super.account, {required this.row, required this.target, required this.entries, required this.transfers, required this.bills})
      : super(movedTo: target?.id);

  final Account row;
  final Account? target;
  final List<Entry> entries;
  final List<Transfer> transfers;
  final List<RecurringItem> bills;
}

String? _blankToNull(String? s) => (s == null || s.trim().isEmpty) ? null : s.trim();
