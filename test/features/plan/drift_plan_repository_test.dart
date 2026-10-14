import 'package:bajet/core/database/app_database.dart';
import 'package:bajet/features/plan/data/drift_plan_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

DateTime d(int y, int m, int day) => DateTime.utc(y, m, day);

void main() {
  late AppDatabase db;
  late DriftPlanRepository plan;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    plan = DriftPlanRepository(db);
  });
  tearDown(() => db.close());

  test('reordering goals rewrites their priorities in the given order', () async {
    final laptop = await plan.addGoal(name: 'Laptop', price: 450000, targetDate: d(2026, 12, 1), priority: 1);
    final holiday = await plan.addGoal(name: 'Holiday', price: 200000, targetDate: d(2027, 3, 1), priority: 2);
    await plan.reorderGoals([holiday, laptop]);
    expect([for (final g in await plan.watchActiveGoals().first) g.name], ['Holiday', 'Laptop']);
  });

  test('a bought goal leaves the active list and is listed as achieved', () async {
    final laptop = await plan.addGoal(name: 'Laptop', price: 450000, targetDate: d(2026, 12, 1));
    await plan.markGoalBought(laptop, on: d(2026, 11, 20));
    expect(await plan.watchActiveGoals().first, isEmpty);
    final done = (await plan.watchAchievedGoals().first).single;
    expect((done.name, done.achievedOn), ('Laptop', d(2026, 11, 20)));
  });
}
