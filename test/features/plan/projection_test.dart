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
  RecurringItem(id: 1, name: 'Salary', amount: 300000, categoryKey: 'salary', isIncome: true, nextDue: d(2026, 10, 25)),
  RecurringItem(id: 2, name: 'Rent', amount: 50000, categoryKey: 'bills', isIncome: false, nextDue: d(2026, 11, 1)),
  RecurringItem(id: 3, name: 'Internet', amount: 12900, categoryKey: 'bills', isIncome: false, nextDue: d(2026, 11, 10)),
  RecurringItem(id: 4, name: 'Phone', amount: 6000, categoryKey: 'bills', isIncome: false, nextDue: d(2026, 10, 20)),
];

final events = [
  PlannedEvent(id: 1, name: 'Car service', amount: 25000, categoryKey: 'other', isIncome: false, date: d(2026, 11, 20)),
  PlannedEvent(id: 2, name: 'Bonus', amount: 50000, categoryKey: 'salary', isIncome: true, date: d(2026, 12, 20), countInProjection: false),
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

  test('runs on past buy day when asked, leaving the outcome as it was', () {
    final p = project(balance: 180000, today: d(2026, 10, 14), rules: rules, recurring: recurring, events: events, goals: [goal], buffer: 100000, through: d(2027, 2, 2));
    expect(p.days.last.date, d(2027, 2, 2));
    expect(p.goals.single.leftAfterBuying, 590300);
    // Sunday rests, then Monday's plan and rent, then Tuesday's plan.
    expect(balanceOn(p, d(2027, 2, 2)), 590300 - 1000 - 50000 - 1000);
  });

  test('the outcome carries the sums that add up to what is left', () {
    // 109 days from Wed 14 Oct: 15 weeks at RM65 plus Wed to Sat at RM45;
    // four salaries; three rents and internet bills, four phone bills and
    // the car service; the bonus is not counted.
    final sums = run().goals.single.sums;
    expect((sums.balanceNow, sums.dailySpending, sums.income, sums.costs, sums.earlierGoals), (180000, 102000, 1200000, 237700, 0));
    expect(sums.balanceNow - sums.dailySpending + sums.income - sums.costs - goal.price, 590300);
  });

  test('pay that lands within a window counts on its last day, a bill on its first', () {
    // Salary between the 25th and 28th; rent between the 1st and the 6th.
    final varying = [
      for (final r in recurring)
        RecurringItem(id: r.id, name: r.name, amount: r.amount, categoryKey: r.categoryKey, isIncome: r.isIncome, nextDue: r.nextDue, windowDays: switch (r.name) { 'Salary' => 3, 'Rent' => 5, _ => 0 }),
    ];
    final p = run(items: varying);
    // Sun 25 Oct is a rest day, so the balance only drops by the next three
    // workdays before the salary counts on Wed 28 Oct.
    expect(balanceOn(p, d(2026, 10, 25)), 163000);
    expect(balanceOn(p, d(2026, 10, 28)), 460000);
    expect(balanceOn(p, d(2026, 11, 1)), 406500);
    expect(p.goals.single.leftAfterBuying, 590300);
  });

  test('a bill gone unpaid past its day is charged today, once a month it was missed; late pay is not counted', () {
    final p = run(items: [
      // Due 10/09 and 10/10 and never marked paid: both still owed.
      RecurringItem(id: 4, name: 'Phone', amount: 6000, categoryKey: 'bills', isIncome: false, nextDue: d(2026, 9, 10)),
      RecurringItem(id: 1, name: 'Salary', amount: 300000, categoryKey: 'salary', isIncome: true, nextDue: d(2026, 10, 10)),
    ]);
    // 1,800.00 − 10.00 planned today − 2 × 60.00 owed.
    expect(balanceOn(p, d(2026, 10, 14)), 167000);
    // The next phone bill falls on 10/11, beside the next pay.
    expect(balanceOn(p, d(2026, 11, 10)) - balanceOn(p, d(2026, 11, 9)), 300000 - 6000 - 1000);
  });

  test('a yearly event is counted every year it falls before buy day', () {
    final p = project(
      balance: 100000,
      today: d(2026, 7, 1),
      rules: const [],
      recurring: const [],
      events: [PlannedEvent(id: 1, name: 'Birthday', amount: 10000, categoryKey: 'gifts', isIncome: false, date: d(2026, 10, 30), repeatsYearly: true)],
      goals: [Goal(id: 1, name: 'Laptop', price: 1000, targetDate: d(2028, 1, 1))],
      buffer: 0,
    );
    // Two birthdays, 2026 and 2027, before the goal on 01/01/2028.
    expect(p.goals.single.sums.costs, 20000);
  });

  test('only what is left of an event budget is still to come', () {
    Projection run(int spent) => project(
          balance: 100000,
          today: d(2026, 7, 1),
          rules: const [],
          recurring: const [],
          events: [PlannedEvent(id: 1, name: 'Birthday', amount: 10000, categoryKey: 'gifts', isIncome: false, date: d(2026, 10, 30), repeatsYearly: true, spent: spent)],
          goals: [Goal(id: 1, name: 'Laptop', price: 1000, targetDate: d(2028, 1, 1))],
          buffer: 0,
        );
    // RM73 of RM100 spent: RM27 left this year, the full RM100 next year.
    expect(run(7300).goals.single.sums.costs, 2700 + 10000);
    expect(run(15000).goals.single.sums.costs, 10000);
  });

  test('today only counts the part of the plan not yet logged', () {
    final p = run(flexSpentToday: 1200);
    expect(balanceOn(p, d(2026, 10, 14)), 180000);
    expect(p.goals.single.leftAfterBuying, 591300);
  });

  test('a recurring item starts at its next due date, not before', () {
    final paidEarly = [
      for (final r in recurring)
        r.id == 4 ? RecurringItem(id: 4, name: 'Phone', amount: 6000, categoryKey: 'bills', isIncome: false, nextDue: d(2026, 11, 20)) : r,
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
