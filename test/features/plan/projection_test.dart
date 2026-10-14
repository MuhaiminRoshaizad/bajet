import 'package:bajet/features/plan/domain/plan_models.dart';
import 'package:bajet/features/plan/domain/projection.dart';
import 'package:flutter_test/flutter_test.dart';

// Demo figures only. Expected values were computed independently of this code.
DateTime d(int y, int m, int day) => DateTime.utc(y, m, day);

const rules = [
  WeeklyRule(weekday: 1, label: 'Workday', type: DayType.spend, plannedSpend: 1000),
  WeeklyRule(weekday: 2, label: 'Workday', type: DayType.spend, plannedSpend: 1000),
  WeeklyRule(weekday: 3, label: 'Workday', type: DayType.spend, plannedSpend: 1000),
  WeeklyRule(weekday: 4, label: 'Workday', type: DayType.spend, plannedSpend: 1000),
  WeeklyRule(weekday: 5, label: 'Workday', type: DayType.spend, plannedSpend: 1000),
  WeeklyRule(weekday: 6, label: 'Weekend', type: DayType.flex, plannedSpend: 1500),
  WeeklyRule(weekday: 7, label: 'Rest', type: DayType.zero, plannedSpend: 0),
];

final recurring = [
  RecurringItem(id: 1, name: 'Salary', amount: 300000, isIncome: true, nextDue: d(2026, 10, 25)),
  RecurringItem(id: 2, name: 'Rent', amount: 50000, isIncome: false, nextDue: d(2026, 11, 1)),
  RecurringItem(id: 3, name: 'Internet', amount: 12900, isIncome: false, nextDue: d(2026, 11, 10)),
  RecurringItem(id: 4, name: 'Phone', amount: 6000, isIncome: false, nextDue: d(2026, 10, 20)),
];

final events = [
  PlannedEvent(id: 1, name: 'Car service', amount: 25000, isIncome: false, date: d(2026, 11, 20)),
  PlannedEvent(id: 2, name: 'Bonus', amount: 50000, isIncome: true, date: d(2026, 12, 20), countInProjection: false),
];

final goal = Goal(id: 1, name: 'Laptop', price: 450000, targetDate: d(2027, 1, 30));

Projection run({int flexSpentToday = 0, List<RecurringItem>? items}) => project(
      balance: 180000,
      today: d(2026, 10, 14),
      rules: rules,
      recurring: items ?? recurring,
      events: events,
      goals: [goal],
      buffer: 100000,
      flexSpentToday: flexSpentToday,
    );

int balanceOn(Projection p, DateTime day) => p.days.firstWhere((x) => x.date == day).balance;

void main() {
  test('follows the rhythm, recurring items and events day by day', () {
    final p = run();
    expect(balanceOn(p, d(2026, 10, 14)), 179000);
    expect(balanceOn(p, d(2026, 10, 20)), 167500);
    expect(balanceOn(p, d(2026, 10, 25)), 463000);
    expect(balanceOn(p, d(2026, 11, 1)), 406500);
    expect(balanceOn(p, d(2026, 11, 20)), 344600);
    expect(balanceOn(p, d(2027, 1, 29)), 1041800);
  });

  test('buys the goal on its target date and judges it against the buffer', () {
    final p = run();
    final buyDay = p.days.last;
    expect(buyDay.date, d(2027, 1, 30));
    expect(buyDay.balanceBeforeGoals, 1040300);
    expect(buyDay.balance, 590300);
    expect(p.goals.single.leftAfterBuying, 590300);
    expect(p.goals.single.onTrack, isTrue);
  });

  test('today only counts the part of the plan not yet logged', () {
    final p = run(flexSpentToday: 1200);
    expect(balanceOn(p, d(2026, 10, 14)), 180000);
    expect(p.goals.single.leftAfterBuying, 591300);
  });

  test('a recurring item starts at its next due date, not before', () {
    final paidEarly = [
      for (final r in recurring)
        r.id == 4 ? RecurringItem(id: 4, name: 'Phone', amount: 6000, isIncome: false, nextDue: d(2026, 11, 20)) : r,
    ];
    expect(balanceOn(run(items: paidEarly), d(2026, 10, 20)), 173500);
  });

  test('events not counted in the projection are ignored', () {
    final p = run();
    // 20/12 is a Sunday with no rhythm spend; only the phone bill applies.
    expect(balanceOn(p, d(2026, 12, 20)), balanceOn(p, d(2026, 12, 19)) - 6000);
  });

  test('without a goal it projects a fixed horizon', () {
    final p = project(balance: 0, today: d(2026, 10, 14), rules: rules, recurring: const [], events: const [], goals: const [], buffer: 0);
    expect(p.days, hasLength(31));
    expect(p.goals, isEmpty);
  });

  group('what if', () {
    int leftWith(WhatIf w) => project(
          balance: 180000,
          today: d(2026, 10, 14),
          rules: rules,
          recurring: recurring,
          events: events,
          goals: [goal],
          buffer: 100000,
          whatIf: w,
        ).goals.single.leftAfterBuying;
    final base = leftWith(WhatIf.none);

    test('spending RM7 more a week costs RM1 a day to buy day', () {
      // 14/10/2026 to 30/01/2027 is 109 days.
      expect(base - leftWith(const WhatIf(weeklyChange: 700)), 109 * 100);
    });

    test('spending less never takes a day below zero', () {
      // RM70 less a week is RM10 a day: the 78 workdays drop to zero, the 16
      // Saturdays to RM5, and the Sundays were already zero.
      final saved = leftWith(const WhatIf(weeklyChange: -7000)) - base;
      expect(saved, (78 * 1000) + (16 * 1000));
    });

    test('a monthly cost lands on each 1st after today', () {
      // 01/11, 01/12 and 01/01 fall before buy day.
      expect(base - leftWith(const WhatIf(monthlyCost: 2000)), 3 * 2000);
    });

    test('unconfirmed income can be counted', () {
      expect(leftWith(const WhatIf(countUnconfirmed: true)) - base, 50000);
    });
  });
}
