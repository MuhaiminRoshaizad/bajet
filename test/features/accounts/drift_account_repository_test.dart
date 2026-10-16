import 'package:bajet/core/database/app_database.dart';
import 'package:bajet/features/accounts/data/drift_account_repository.dart';
import 'package:bajet/features/accounts/domain/account_models.dart' as domain;
import 'package:bajet/features/ledger/data/drift_ledger_repository.dart';
import 'package:bajet/features/ledger/domain/ledger_models.dart';
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
}
