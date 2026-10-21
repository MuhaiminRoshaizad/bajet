import 'dart:convert';

import 'package:bajet/core/database/app_database.dart' hide Checkin;
import 'package:bajet/features/accounts/data/drift_account_repository.dart';
import 'package:bajet/features/accounts/domain/account_models.dart' as domain;
import 'package:bajet/features/accounts/domain/account_models.dart' show firstAccountName;
import 'package:bajet/features/backup/data/drift_backup_repository.dart';
import 'package:bajet/features/backup/domain/backup_repository.dart';
import 'package:bajet/features/checkin/data/drift_checkin_repository.dart';
import 'package:bajet/features/checkin/domain/checkin.dart';
import 'package:bajet/features/ledger/data/drift_ledger_repository.dart';
import 'package:bajet/features/ledger/domain/ledger_models.dart';
import 'package:bajet/features/plan/data/drift_plan_repository.dart';
import 'package:bajet/features/plan/domain/plan_repository.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

DateTime d(int y, int m, int day) => DateTime.utc(y, m, day);

void main() {
  late AppDatabase source;
  late AppDatabase target;

  setUp(() {
    source = AppDatabase(NativeDatabase.memory());
    target = AppDatabase(NativeDatabase.memory());
  });
  tearDown(() async {
    await source.close();
    await target.close();
  });

  // Something must exist for an entry to belong to.
  Future<void> anAccount(AppDatabase db) =>
      db.into(db.accounts).insert(AccountsCompanion.insert(kind: AccountKind.bank, name: 'Bank', color: 0xFF4A5866));

  Future<void> fill(AppDatabase db) async {
    final plan = DriftPlanRepository(db);
    final ledger = DriftLedgerRepository(db);
    await plan.saveSettings(PlanSettings(openingDate: d(2026, 7, 1), weeklyCap: 5000, buffer: 50000));
    await db.into(db.accounts).insert(AccountsCompanion.insert(kind: AccountKind.bank, name: firstAccountName, openingBalance: const Value(150000), color: 0xFF4A5866));
    final rent = await plan.addRecurring(name: 'Rent', isIncome: false, amount: 50000, categoryKey: 'bills', nextDue: d(2026, 7, 1));
    await plan.confirmRecurring(rent, due: d(2026, 7, 1), paidOn: d(2026, 7, 1));
    await plan.addEvent(name: 'Bonus', isIncome: true, amount: 30000, categoryKey: 'salary', date: d(2026, 9, 1), countInProjection: false);
    await plan.addGoal(name: 'Laptop', price: 450000, targetDate: d(2026, 12, 1));
    await ledger.add(EntryDraft(day: d(2026, 7, 2), isIncome: false, amount: 450, categoryKey: 'food', label: 'Coffee', note: 'Morning'));
    await DriftFavouriteRepository(db).add(label: 'Coffee', categoryKey: 'food', amount: 450);
    await DriftCheckinRepository(db).save(Checkin(
      checkedOn: d(2026, 7, 5),
      balance: 99550,
      matched: true,
      startingAdjustment: 120,
      allowanceSpent: 450,
      leftAfterBuying: 52000,
      nextTarget: 96000,
    ));
  }

  test('a backup restored elsewhere reproduces every table', () async {
    await fill(source);
    final backup = await DriftBackupRepository(source).export();
    // Through real JSON text, as a file would carry it.
    final decoded = jsonDecode(jsonEncode(backup)) as Map<String, Object?>;
    await DriftBackupRepository(target).restore(decoded);

    expect(await DriftBackupRepository(target).export(), backup);
    expect(await DriftLedgerRepository(target).watchBalance().first, 150000 - 50000 - 450);
  });

  test('restore replaces what was there', () async {
    await anAccount(target);
    await DriftLedgerRepository(target).add(EntryDraft(day: d(2026, 6, 1), isIncome: false, amount: 999, categoryKey: 'other'));
    await fill(source);
    await DriftBackupRepository(target).restore(jsonDecode(jsonEncode(await DriftBackupRepository(source).export())) as Map<String, Object?>);
    final amounts = (await DriftLedgerRepository(target).watchSince(d(2000, 1, 1)).first).map((e) => e.amount);
    expect(amounts, isNot(contains(999)));
  });

  test('refuses a file that is not a bajet backup and leaves data alone', () async {
    await fill(target);
    final before = await DriftBackupRepository(target).export();
    await expectLater(DriftBackupRepository(target).restore({'app': 'other'}), throwsA(isA<BackupFormatException>()));
    await expectLater(DriftBackupRepository(target).restore({'app': 'bajet', 'format': 99}), throwsA(isA<BackupFormatException>()));
    expect(await DriftBackupRepository(target).export(), before);
  });

  test('a damaged backup is refused without losing anything', () async {
    await fill(target);
    final before = await DriftBackupRepository(target).export();
    final damaged = {...before, 'entries': [{'id': 'not a number'}]};
    await expectLater(DriftBackupRepository(target).restore(damaged), throwsA(isA<BackupFormatException>()));
    expect(await DriftBackupRepository(target).export(), before);
  });

  test('a backup whose rows break the rules, such as an amount of zero, is refused without losing anything', () async {
    await fill(target);
    final before = await DriftBackupRepository(target).export();
    final entry = {...((before['entries']! as List).first as Map<String, Object?>), 'amount': 0};
    await expectLater(DriftBackupRepository(target).restore({...before, 'entries': [entry]}), throwsA(isA<BackupFormatException>()));
    expect(await DriftBackupRepository(target).export(), before);
  });

  test('restoring a backup from before the Untracked category adds it back', () async {
    await fill(source);
    final backup = await DriftBackupRepository(source).export();
    final older = {...backup, 'categories': [for (final c in backup['categories']! as List) if ((c as Map)['key'] != 'untracked') c]};
    await DriftBackupRepository(target).restore(jsonDecode(jsonEncode(older)) as Map<String, Object?>);
    final keys = [for (final c in await target.select(target.categories).get()) c.key];
    expect(keys, contains('untracked'));
  });

  test('a format 1 backup, from before receipts, still restores', () async {
    await fill(source);
    final v2 = jsonDecode(jsonEncode(await DriftBackupRepository(source).export())) as Map<String, Object?>;
    final v1 = {
      ...v2,
      'format': 1,
      'entries': [for (final e in v2['entries']! as List) {...(e as Map<String, Object?>)}..remove('receipt')],
    };
    await DriftBackupRepository(target).restore(v1);
    final restored = await DriftLedgerRepository(target).watchSince(d(2000, 1, 1)).first;
    expect(restored.firstWhere((e) => e.label == 'Coffee').receipt, isNull);
  });

  test('a format 2 backup, from before pay windows, restores with fixed days', () async {
    await fill(source);
    final v3 = jsonDecode(jsonEncode(await DriftBackupRepository(source).export())) as Map<String, Object?>;
    final v2 = {
      ...v3,
      'format': 2,
      'recurringItems': [for (final r in v3['recurringItems']! as List) {...(r as Map<String, Object?>)}..remove('windowDays')],
    };
    await DriftBackupRepository(target).restore(v2);
    final restored = await DriftPlanRepository(target).watchRecurring().first;
    expect([for (final r in restored) (r.name, r.windowDays)], [('Rent', 0)]);
  });

  test('a pay window survives a round trip', () async {
    await fill(source);
    await DriftPlanRepository(source).addRecurring(name: 'Salary', isIncome: true, amount: 300000, categoryKey: 'salary', nextDue: d(2026, 7, 25), windowDays: 3);
    await DriftBackupRepository(target).restore(jsonDecode(jsonEncode(await DriftBackupRepository(source).export())) as Map<String, Object?>);
    final restored = await DriftPlanRepository(target).watchRecurring().first;
    expect(restored.firstWhere((r) => r.name == 'Salary').windowDays, 3);
  });

  test('a format 3 backup, from before yearly events, restores them as one-off', () async {
    await fill(source);
    final v4 = jsonDecode(jsonEncode(await DriftBackupRepository(source).export())) as Map<String, Object?>;
    final v3 = {
      ...v4,
      'format': 3,
      'plannedEvents': [for (final e in v4['plannedEvents']! as List) {...(e as Map<String, Object?>)}..remove('repeatsYearly')],
    };
    await DriftBackupRepository(target).restore(v3);
    expect([for (final e in await DriftPlanRepository(target).watchEvents().first) e.repeatsYearly], [false]);
  });

  test('a yearly event survives a round trip', () async {
    await fill(source);
    await DriftPlanRepository(source).addEvent(name: 'Birthday', isIncome: false, amount: 10000, categoryKey: 'gifts', date: d(2026, 10, 30), repeatsYearly: true);
    await DriftBackupRepository(target).restore(jsonDecode(jsonEncode(await DriftBackupRepository(source).export())) as Map<String, Object?>);
    final birthday = (await DriftPlanRepository(target).watchEvents().first).firstWhere((e) => e.name == 'Birthday');
    expect(birthday.repeatsYearly, isTrue);
  });

  test('a format 4 backup, from before event spending, restores with no links', () async {
    await fill(source);
    final v5 = jsonDecode(jsonEncode(await DriftBackupRepository(source).export())) as Map<String, Object?>;
    final v4 = {
      ...v5,
      'format': 4,
      'entries': [
        for (final e in v5['entries']! as List) {...(e as Map<String, Object?>)}..remove('plannedEventId')..remove('plannedEventOn'),
      ],
    };
    await DriftBackupRepository(target).restore(v4);
    final restored = await DriftLedgerRepository(target).watchSince(d(2000, 1, 1)).first;
    expect(restored.every((e) => e.event == null), isTrue);
  });

  test('spending against an event survives a round trip', () async {
    await fill(source);
    final id = await DriftPlanRepository(source).addEvent(name: 'Birthday', isIncome: false, amount: 10000, categoryKey: 'gifts', date: d(2026, 10, 30));
    await DriftLedgerRepository(source).add(EntryDraft(day: d(2026, 10, 25), isIncome: false, amount: 4500, categoryKey: 'food', event: EventLink(id, d(2026, 10, 30))));
    await DriftBackupRepository(target).restore(jsonDecode(jsonEncode(await DriftBackupRepository(source).export())) as Map<String, Object?>);
    final birthday = (await DriftPlanRepository(target).watchEvents().first).firstWhere((e) => e.name == 'Birthday');
    expect(birthday.spent, 4500);
  });

  test('a format 5 backup, from before accounts, restores into one account holding its balance', () async {
    await fill(source);
    final v6 = jsonDecode(jsonEncode(await DriftBackupRepository(source).export())) as Map<String, Object?>;
    final settings = v6['settings']! as Map<String, Object?>;
    final v5 = {
      ...v6,
      'format': 5,
      'settings': {...settings, 'openingBalance': 150000}..remove('totalCardColor')..remove('totalCardFinish'),
      'entries': [for (final e in v6['entries']! as List) {...(e as Map<String, Object?>)}..remove('accountId')],
      'recurringItems': [for (final r in v6['recurringItems']! as List) {...(r as Map<String, Object?>)}..remove('accountId')],
    }
      ..remove('accounts')
      ..remove('transfers');
    await DriftBackupRepository(target).restore(v5);

    final accounts = await DriftAccountRepository(target).watchAccounts().first;
    expect([for (final a in accounts) (a.name, a.openingBalance)], [(domain.firstAccountName, 150000)]);
    expect(await DriftLedgerRepository(target).watchBalance().first, 150000 - 50000 - 450);
  });

  test('a format 6 backup restores its brushed metal cards, and the total card, as matte', () async {
    await fill(source);
    await DriftAccountRepository(source).saveTotalLook(const domain.TotalCardLook(color: 0xFFCDB88A, finish: domain.CardFinish.gloss));
    final v7 = jsonDecode(jsonEncode(await DriftBackupRepository(source).export())) as Map<String, Object?>;
    final v6 = {
      ...v7,
      'format': 6,
      'settings': {...v7['settings']! as Map<String, Object?>, 'totalCardFinish': 'brushed'},
      'accounts': [for (final a in v7['accounts']! as List) {...(a as Map<String, Object?>), 'finish': 'brushed'}],
    };
    await DriftBackupRepository(target).restore(v6);

    final accounts = await DriftAccountRepository(target).watchAccounts().first;
    expect(accounts.map((a) => a.look.finish), everyElement(domain.CardFinish.matte));
    expect((await DriftAccountRepository(target).watchTotalLook().first).finish, domain.CardFinish.matte);
  });

  test('accounts, the money moved between them and the total card survive a round trip', () async {
    await fill(source);
    final accounts = DriftAccountRepository(source);
    final cash = await accounts.addAccount(const domain.AccountDraft(
      kind: domain.AccountKind.cash,
      name: 'Cash',
      nickname: 'Wallet',
      balance: 8450,
      look: domain.CardLook(color: 0xFF6B3F24, finish: domain.CardFinish.leather),
    ));
    await accounts.transfer(fromId: 1, toId: cash, amount: 5000, day: d(2026, 7, 3), note: 'ATM');
    await accounts.saveTotalLook(const domain.TotalCardLook(color: 0xFFCDB88A, finish: domain.CardFinish.gloss));
    await DriftLedgerRepository(source).add(EntryDraft(day: d(2026, 7, 3), isIncome: false, amount: 570, categoryKey: 'food', accountId: cash));

    final backup = jsonDecode(jsonEncode(await DriftBackupRepository(source).export())) as Map<String, Object?>;
    await DriftBackupRepository(target).restore(backup);
    expect(await DriftBackupRepository(target).export(), backup);
    final restored = {for (final a in await DriftAccountRepository(target).watchAccounts().first) a.name: a.balance};
    expect(restored, {domain.firstAccountName: 150000 - 50000 - 450 - 5000, 'Cash': 8450 + 5000 - 570});
    expect(await DriftAccountRepository(target).watchTotalLook().first, const domain.TotalCardLook(color: 0xFFCDB88A, finish: domain.CardFinish.gloss));
  });

  test('receipts survive a round trip by file name', () async {
    await anAccount(source);
    await DriftLedgerRepository(source).add(EntryDraft(day: d(2026, 7, 3), isIncome: false, amount: 1200, categoryKey: 'food', receipt: 'r1.jpg'));
    await DriftBackupRepository(target).restore(jsonDecode(jsonEncode(await DriftBackupRepository(source).export())) as Map<String, Object?>);
    expect((await DriftLedgerRepository(target).watchSince(d(2000, 1, 1)).first).single.receipt, 'r1.jpg');
  });

  test('a format 7 backup, from before saved check-ins, restores with none', () async {
    await fill(source);
    final v8 = jsonDecode(jsonEncode(await DriftBackupRepository(source).export())) as Map<String, Object?>;
    final v7 = {...v8, 'format': 7}..remove('checkins');
    await DriftBackupRepository(target).restore(v7);
    expect(await DriftCheckinRepository(target).watchCheckins().first, isEmpty);
    expect(await DriftLedgerRepository(target).watchBalance().first, 150000 - 50000 - 450);
  });

  test("the user's name survives a round trip, and a format 8 backup restores with none", () async {
    await fill(source);
    await source.update(source.appSettings).write(const AppSettingsCompanion(userName: Value('Sara')));
    final v9 = jsonDecode(jsonEncode(await DriftBackupRepository(source).export())) as Map<String, Object?>;
    await DriftBackupRepository(target).restore(v9);
    expect((await target.select(target.appSettings).getSingle()).userName, 'Sara');

    final v8 = {...v9, 'format': 8, 'settings': {...v9['settings']! as Map<String, Object?>}..remove('userName')};
    await DriftBackupRepository(target).restore(v8);
    expect((await target.select(target.appSettings).getSingle()).userName, isNull);
  });

  test("a goal's listing and what it showed survive a round trip, and a format 9 backup restores with no check", () async {
    await fill(source);
    await source.update(source.goals).write(GoalsCompanion(
      listingUrl: const Value('https://example.com/item/1'),
      listingState: const Value(ListingState.sold),
      listingCheckedOn: Value(d(2026, 10, 22)),
    ));
    final v10 = jsonDecode(jsonEncode(await DriftBackupRepository(source).export())) as Map<String, Object?>;
    await DriftBackupRepository(target).restore(v10);
    final goal = await target.select(target.goals).getSingle();
    expect((goal.listingUrl, goal.listingState, goal.listingCheckedOn), ('https://example.com/item/1', ListingState.sold, d(2026, 10, 22)));

    final v9 = {
      ...v10,
      'format': 9,
      'goals': [for (final g in v10['goals']! as List) {...(g as Map<String, Object?>)}..remove('listingState')..remove('listingCheckedOn')],
    };
    await DriftBackupRepository(target).restore(v9);
    final older = await target.select(target.goals).getSingle();
    expect((older.listingUrl, older.listingState, older.listingCheckedOn), ('https://example.com/item/1', null, null));
  });
}
