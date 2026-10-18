import 'package:bajet/features/checkin/domain/checkin.dart';
import 'package:bajet/features/plan/domain/plan_models.dart';
import 'package:bajet/features/plan/domain/projection.dart';
import 'package:flutter_test/flutter_test.dart';

// Demo figures only.
DateTime d(int m, int day) => DateTime.utc(2026, m, day);

void main() {
  final sunday = d(10, 25);
  final projection = project(
    balance: 401745,
    today: sunday,
    rules: [for (var w = 1; w <= 7; w++) WeeklyRule(weekday: w, label: 'Day', type: DayType.spend, plannedSpend: 1000)],
    recurring: const [],
    events: const [],
    goals: [Goal(id: 1, name: 'Laptop', price: 300000, targetDate: d(10, 28))],
    buffer: 100000,
    through: d(11, 1),
  );

  Checkin finish({required bool first, int untracked = 1250}) => finishCheckin(
        today: sunday,
        balance: 401745,
        matched: true,
        untrackedToday: untracked,
        first: first,
        allowanceSpent: 2150,
        projection: projection,
      );

  test('the target is what the plan expects a week on, even past buy day', () {
    final c = finish(first: false);
    // Today's plan and six more days at RM10.00, and the laptop on the 28th.
    expect(c.nextTarget, 401745 - 7000 - 1000 - 300000);
    expect(c.targetOn, d(11, 1));
    expect(c.leftAfterBuying, 401745 - 4000 - 300000);
  });

  test('money found at the first check-in is a starting adjustment, later it is untracked', () {
    expect((finish(first: true).startingAdjustment, finish(first: true).untracked), (1250, 0));
    expect((finish(first: false).startingAdjustment, finish(first: false).untracked), (0, 1250));
  });
}
