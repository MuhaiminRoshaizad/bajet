import 'package:bajet/core/database/app_database.dart';
import 'package:bajet/core/database/demo_data.dart';
import 'package:bajet/features/ledger/data/drift_ledger_repository.dart';
import 'package:bajet/features/plan/data/drift_plan_repository.dart';
import 'package:bajet/features/plan/domain/projection.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Several days of the month, so the bills before and after today both work.
  for (final today in [DateTime.utc(2026, 7, 1), DateTime.utc(2026, 7, 14), DateTime.utc(2026, 7, 30)]) {
    test('demo data on ${today.day}/${today.month} is set up, logged and on track', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      await fillWithDemoData(db, today);

      final ledger = DriftLedgerRepository(db);
      final plan = DriftPlanRepository(db);
      final balance = (await ledger.watchBalance().first)!;
      final recurring = await plan.watchRecurring().first;
      expect(balance, greaterThan(0));
      expect(await ledger.watchSince(DateTime.utc(2000)).first, hasLength(greaterThan(20)));
      // Every bill and income is next due after today, as if confirmed so far.
      expect(recurring.every((r) => r.nextDue.isAfter(today)), isTrue);

      final p = project(
        balance: balance,
        today: today,
        rules: await plan.watchRules().first,
        recurring: recurring,
        events: await plan.watchEvents().first,
        goals: await plan.watchActiveGoals().first,
        buffer: (await plan.watchSettings().first)!.buffer,
      );
      expect(p.goals.single.goal.name, 'Laptop');
      expect(p.goals.single.onTrack, isTrue);
    });
  }
}
