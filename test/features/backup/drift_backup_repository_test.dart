import 'dart:convert';

import 'package:bajet/core/database/app_database.dart';
import 'package:bajet/features/backup/data/drift_backup_repository.dart';
import 'package:bajet/features/backup/domain/backup_repository.dart';
import 'package:bajet/features/ledger/data/drift_ledger_repository.dart';
import 'package:bajet/features/ledger/domain/ledger_models.dart';
import 'package:bajet/features/plan/data/drift_plan_repository.dart';
import 'package:bajet/features/plan/domain/plan_repository.dart';
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

  Future<void> fill(AppDatabase db) async {
    final plan = DriftPlanRepository(db);
    final ledger = DriftLedgerRepository(db);
    await plan.saveSettings(PlanSettings(openingBalance: 150000, openingDate: d(2026, 7, 1), weeklyCap: 5000, buffer: 50000));
    final rent = await plan.addRecurring(name: 'Rent', isIncome: false, amount: 50000, categoryKey: 'bills', nextDue: d(2026, 7, 1));
    await plan.confirmRecurring(rent, paidOn: d(2026, 7, 1));
    await plan.addEvent(name: 'Bonus', isIncome: true, amount: 30000, categoryKey: 'salary', date: d(2026, 9, 1), countInProjection: false);
    await plan.addGoal(name: 'Laptop', price: 450000, targetDate: d(2026, 12, 1));
    await ledger.add(EntryDraft(day: d(2026, 7, 2), isIncome: false, amount: 450, categoryKey: 'food', label: 'Coffee', note: 'Morning'));
    await DriftFavouriteRepository(db).add(label: 'Coffee', categoryKey: 'food', amount: 450);
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
}
