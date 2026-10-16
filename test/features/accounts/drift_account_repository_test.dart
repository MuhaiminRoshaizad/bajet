import 'package:bajet/core/database/app_database.dart';
import 'package:bajet/features/accounts/data/drift_account_repository.dart';
import 'package:bajet/features/accounts/domain/account_models.dart' as domain;
import 'package:bajet/features/ledger/data/drift_ledger_repository.dart';
import 'package:bajet/features/ledger/domain/ledger_models.dart';
import 'package:bajet/features/plan/data/drift_plan_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

DateTime d(int y, int m, int day) => DateTime.utc(y, m, day);

void main() {
  late AppDatabase db;
  late DriftAccountRepository accounts;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    accounts = DriftAccountRepository(db);
    await db.into(db.appSettings).insert(AppSettingsCompanion.insert(openingDate: d(2026, 7, 1), weeklyCap: 5000, buffer: 0));
  });
  tearDown(() => db.close());

  const slate = domain.CardLook(color: 0xFF4A5866);
  const leather = domain.CardLook(color: 0xFF6B3F24, finish: domain.CardFinish.leather);

  Future<(int, int)> bankAndCash() async => (
        await accounts.addAccount(const domain.AccountDraft(kind: domain.AccountKind.bank, name: 'Bank', nickname: 'Savings', balance: 100000, look: slate)),
        await accounts.addAccount(const domain.AccountDraft(kind: domain.AccountKind.cash, name: 'Cash', balance: 8450, look: leather)),
      );

  test('accounts come in the order they were added, each holding what it was opened with', () async {
    await bankAndCash();
    final all = await accounts.watchAccounts().first;
    expect([for (final a in all) (a.name, a.nickname, a.balance, a.look)], [('Bank', 'Savings', 100000, slate), ('Cash', null, 8450, leather)]);
  });

  test('a balance follows its own entries and transfers, and they add up to the total', () async {
    final (bank, cash) = await bankAndCash();
    final ledger = DriftLedgerRepository(db);
    await ledger.add(EntryDraft(day: d(2026, 7, 2), isIncome: false, amount: 570, categoryKey: 'food', accountId: cash));
    await ledger.add(EntryDraft(day: d(2026, 7, 2), isIncome: true, amount: 300000, categoryKey: 'salary', accountId: bank));
    await accounts.transfer(fromId: bank, toId: cash, amount: 5000, day: d(2026, 7, 3));

    final all = {for (final a in await accounts.watchAccounts().first) a.id: a.balance};
    expect(all, {bank: 100000 + 300000 - 5000, cash: 8450 - 570 + 5000});
    expect(await ledger.watchBalance().first, all.values.reduce((a, b) => a + b));
  });

  test('transfers come newest first, the later of a day on top, and a deleted one is gone', () async {
    final (bank, cash) = await bankAndCash();
    final early = await accounts.transfer(fromId: bank, toId: cash, amount: 1000, day: d(2026, 7, 2));
    final first = await accounts.transfer(fromId: cash, toId: bank, amount: 200, day: d(2026, 7, 5), note: 'Change');
    final second = await accounts.transfer(fromId: bank, toId: cash, amount: 300, day: d(2026, 7, 5));
    var all = await accounts.watchTransfers().first;
    expect([for (final t in all) t.id], [second, first, early]);
    expect((all[1].fromId, all[1].toId, all[1].amount, all[1].day, all[1].note), (cash, bank, 200, d(2026, 7, 5), 'Change'));

    await accounts.deleteTransfer(first);
    all = await accounts.watchTransfers().first;
    expect([for (final t in all) t.id], [second, early]);
  });

  test('reordering changes the order everywhere, never a balance, and lasts', () async {
    final (bank, cash) = await bankAndCash();
    final third = await accounts.addAccount(const domain.AccountDraft(kind: domain.AccountKind.ewallet, name: 'Wallet', balance: 500, look: slate));
    await accounts.reorderAccounts([third, cash, bank]);
    final all = await accounts.watchAccounts().first;
    expect([for (final a in all) (a.id, a.balance)], [(third, 500), (cash, 8450), (bank, 100000)]);

    // A new account still goes last.
    final fourth = await accounts.addAccount(const domain.AccountDraft(kind: domain.AccountKind.bank, name: 'Other', balance: 0, look: slate));
    expect([for (final a in await accounts.watchAccounts().first) a.id], [third, cash, bank, fourth]);
  });

  test('editing changes the name, nickname and card, never the balance', () async {
    final (bank, _) = await bankAndCash();
    final before = (await accounts.watchAccounts().first).firstWhere((a) => a.id == bank);
    await accounts.updateAccount(before.copyWith(nickname: () => ' ', look: const domain.CardLook(color: 0xFF151515, ink: 0xFFE6C674)));
    final after = (await accounts.watchAccounts().first).firstWhere((a) => a.id == bank);
    expect((after.nickname, after.look.ink, after.balance), (null, 0xFFE6C674, before.balance));
  });

  test('the total card follows the app until it is given a colour', () async {
    expect(await accounts.watchTotalLook().first, const domain.TotalCardLook());
    await accounts.saveTotalLook(const domain.TotalCardLook(color: 0xFFCDB88A, finish: domain.CardFinish.gloss));
    expect(await accounts.watchTotalLook().first, const domain.TotalCardLook(color: 0xFFCDB88A, finish: domain.CardFinish.gloss));
  });

  group('deleting an account', () {
    late DriftLedgerRepository ledger;
    late DriftPlanRepository plan;
    late int bank, cash, wallet;

    // Cash with a lunch, a bill, a top-up from the bank and a transfer on to
    // an e-wallet.
    setUp(() async {
      ledger = DriftLedgerRepository(db);
      plan = DriftPlanRepository(db);
      (bank, cash) = await bankAndCash();
      wallet = await accounts.addAccount(const domain.AccountDraft(kind: domain.AccountKind.ewallet, name: 'Wallet', balance: 2000, look: slate));
      await ledger.add(EntryDraft(day: d(2026, 7, 2), isIncome: false, amount: 1200, categoryKey: 'food', label: 'Lunch', accountId: cash));
      await plan.addRecurring(name: 'Phone', isIncome: false, amount: 3000, categoryKey: 'bills', nextDue: d(2026, 8, 1), accountId: cash);
      await accounts.transfer(fromId: bank, toId: cash, amount: 5000, day: d(2026, 7, 3));
      await accounts.transfer(fromId: cash, toId: wallet, amount: 1000, day: d(2026, 7, 4));
    });

    Future<Map<int, int>> balances() async => {for (final a in await accounts.watchAccounts().first) a.id: a.balance};

    test('counts what still points at it', () async {
      final use = await accounts.accountUse(cash);
      expect((use.entries, use.transfers, use.isEmpty), (1, 2, false));
      expect(use.bills, ['Phone']);
      expect((await accounts.accountUse(wallet)).entries, 0);
    });

    test('moving its history keeps the total, and the money lands in the account chosen', () async {
      final before = await balances();
      final total = await ledger.watchBalance().first;
      await accounts.deleteAccount(cash, moveTo: bank);

      final after = await balances();
      expect(after.keys, [bank, wallet]);
      expect(after[bank], before[bank]! + before[cash]!);
      expect(after[wallet], before[wallet]);
      expect(await ledger.watchBalance().first, total);
      final lunch = (await ledger.watchSince(d(2026, 7, 1)).first).single;
      expect(lunch.accountId, bank);
      expect((await plan.watchRecurring().first).single.accountId, bank);
      // The top-up from the bank would now go from the bank to itself, so it
      // is gone; the one on to the wallet comes from the bank instead.
      final transfers = await accounts.watchTransfers().first;
      expect([for (final t in transfers) (t.fromId, t.toId, t.amount)], [(bank, wallet, 1000)]);
    });

    test('deleting its history too takes its entries, bills and transfers with it', () async {
      await accounts.deleteAccount(cash);
      expect((await balances()).keys, [bank, wallet]);
      expect(await ledger.watchSince(d(2026, 7, 1)).first, isEmpty);
      expect(await plan.watchRecurring().first, isEmpty);
      expect(await accounts.watchTransfers().first, isEmpty);
      expect(await balances(), {bank: 100000, wallet: 2000});
    });

    test('undo puts every row back as it was, after either kind', () async {
      final before = await balances();
      for (final moveTo in [bank, null]) {
        final removal = await accounts.deleteAccount(cash, moveTo: moveTo);
        expect(removal.account.id, cash);
        await accounts.restoreAccount(removal);
        expect(await balances(), before);
        expect([for (final a in await accounts.watchAccounts().first) a.name], ['Bank', 'Cash', 'Wallet']);
        expect((await ledger.watchSince(d(2026, 7, 1)).first).single.accountId, cash);
        expect((await plan.watchRecurring().first).single.accountId, cash);
        expect([for (final t in await accounts.watchTransfers().first) (t.fromId, t.toId)], [(cash, wallet), (bank, cash)]);
      }
    });

    test('the last account always stays', () async {
      await accounts.deleteAccount(cash);
      await accounts.deleteAccount(wallet, moveTo: bank);
      expect(() => accounts.deleteAccount(bank), throwsStateError);
      expect((await balances()).keys, [bank]);
    });
  });
}
