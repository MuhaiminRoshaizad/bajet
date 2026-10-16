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

String? _blankToNull(String? s) => (s == null || s.trim().isEmpty) ? null : s.trim();
