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

  test('editing a bill or income changes it in place and keeps its kind', () async {
    final id = await plan.addRecurring(name: 'Pay', isIncome: true, amount: 300000, categoryKey: 'salary', nextDue: DateTime.utc(2026, 7, 25));
    final pay = (await plan.watchRecurring().first).single;
    await plan.updateRecurring(pay.copyWith(name: 'Salary', amount: 320000, nextDue: DateTime.utc(2026, 7, 24), windowDays: 4));

    final saved = (await plan.watchRecurring().first).single;
    expect((saved.id, saved.name, saved.amount, saved.categoryKey, saved.isIncome, saved.nextDue, saved.windowDays),
        (id, 'Salary', 320000, 'salary', true, DateTime.utc(2026, 7, 24), 4));
  });

  test('a goal can be edited, deleted and put back exactly as it was', () async {
    final id = await plan.addGoal(name: 'Laptop', price: 450000, targetDate: d(2026, 12, 1), priority: 2);
    final laptop = (await plan.watchActiveGoals().first).single;
    await plan.updateGoal(laptop.copyWith(name: 'New laptop', price: 480000));
    expect((await plan.watchActiveGoals().first).single.price, 480000);

    final edited = (await plan.watchActiveGoals().first).single;
    await plan.deleteGoal(id);
    expect(await plan.watchActiveGoals().first, isEmpty);
    await plan.restoreGoal(edited);
    final back = (await plan.watchActiveGoals().first).single;
    expect((back.id, back.name, back.price, back.priority), (id, 'New laptop', 480000, 2));
  });

  test('a bought goal restores as bought', () async {
    final id = await plan.addGoal(name: 'Laptop', price: 450000, targetDate: d(2026, 12, 1));
    await plan.markGoalBought(id, on: d(2026, 11, 20));
    final bought = (await plan.watchAchievedGoals().first).single;
    await plan.deleteGoal(id);
    await plan.restoreGoal(bought);
    expect((await plan.watchAchievedGoals().first).single.achievedOn, d(2026, 11, 20));
    expect(await plan.watchActiveGoals().first, isEmpty);
  });
}
