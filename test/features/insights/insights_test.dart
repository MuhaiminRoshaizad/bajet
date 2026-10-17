import 'package:bajet/features/insights/domain/insights.dart';
import 'package:bajet/features/ledger/domain/ledger_models.dart';
import 'package:bajet/features/plan/domain/plan_models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_repositories.dart';

// Demo figures only. Expected values were worked out by hand.
DateTime d(int m, int day) => DateTime.utc(2026, m, day);
var _id = 0;
Entry out(DateTime day, int amount, String category, [String? label]) =>
    Entry(id: ++_id, day: day, isIncome: false, amount: amount, categoryKey: category, label: label);

final rules = [for (var w = 1; w <= 7; w++) WeeklyRule(weekday: w, label: 'Day', type: DayType.spend, plannedSpend: w <= 5 ? 1000 : 500)];
final entries = [
  Entry(id: ++_id, day: d(7, 1), isIncome: true, amount: 300000, categoryKey: 'salary', label: 'Salary'),
  out(d(6, 30), 999, 'food'), // logged back, before the opening date
  out(d(7, 3), 50000, 'bills', 'Rent'),
  out(d(7, 6), 800, 'food', 'Lunch'),
  out(d(7, 7), 1200, 'food', 'Lunch'),
  out(d(7, 8), 3000, 'transport', 'Fuel'),
  out(d(7, 13), 700, 'food', 'Lunch'),
  out(d(7, 14), 2000, untrackedCategoryKey, 'Untracked'),
  out(d(7, 15), 450, 'food', 'Coffee'),
];

Insights run(InsightsPeriod period) => insights(
      period: period,
      today: d(7, 15),
      openingDate: d(7, 1),
      weeklyCap: 5000,
      entries: entries,
      categories: demoCategories,
      rules: rules,
    );

void main() {
  test('a month splits money out into fixed, flexible and untracked', () {
    final i = run(InsightsPeriod.month);
    expect((i.from, i.to), (d(7, 1), d(7, 15)));
    expect((i.moneyIn, i.moneyOut, i.kept), (300000, 58150, 241850));
    expect((i.fixedOut, i.flexibleOut, i.untrackedOut), (50000, 6150, 2000));
    expect(i.flexibleByCategory, [('food', 3150), ('transport', 3000)]);
  });

  test('habits count finished days and whole weeks only', () {
    final i = run(InsightsPeriod.month);
    expect((i.daysSoFar, i.zeroSpendDays, i.daysWithinPlan), (14, 10, 12));
    expect((i.weeksUnderAllowance, i.fullWeeks), (1, 1));
    expect(i.daysLogged, 8);
    expect((i.frequent!.label, i.frequent!.count, i.frequent!.average), ('Lunch', 3, 900));
    expect(i.biggest!.label, 'Fuel');
  });

  test('the last fourteen days compare each day with its plan', () {
    final days = run(InsightsPeriod.week).lastDays;
    expect(days, hasLength(14));
    expect((days.last.date, days.last.spent, days.last.planned), (d(7, 15), 450, 1000));
    expect(days.firstWhere((x) => x.date == d(7, 8)).over, isTrue);
  });

  test('a week starts on Monday and has no whole week yet midweek', () {
    final i = run(InsightsPeriod.week);
    expect(i.from, d(7, 13));
    expect((i.moneyIn, i.moneyOut, i.flexibleOut), (0, 3150, 1150));
    expect((i.daysSoFar, i.zeroSpendDays, i.fullWeeks), (2, 1, 0));
  });

  test('all time starts at the earliest entry, even one logged back before the opening date', () {
    final i = run(InsightsPeriod.all);
    expect(i.from, d(6, 30));
    expect(i.moneyOut, 58150 + 999);
  });

  test('with nothing logged before it, all time starts at the opening date', () {
    final i = insights(
      period: InsightsPeriod.all,
      today: d(7, 15),
      openingDate: d(7, 1),
      weeklyCap: 5000,
      entries: entries.where((e) => !e.day.isBefore(d(7, 1))).toList(),
      categories: demoCategories,
      rules: rules,
    );
    expect((i.from, i.moneyOut), (d(7, 1), 58150));
  });

  test('a day logged back before the opening date counts, and days before that carry nothing', () {
    final early = insights(
      period: InsightsPeriod.week,
      today: d(7, 3),
      openingDate: d(7, 1),
      weeklyCap: 5000,
      entries: entries,
      categories: demoCategories,
      rules: rules,
    ).lastDays;
    expect(early.where((x) => x.date.isBefore(d(6, 30))).every((x) => x.planned == 0 && x.spent == 0), isTrue);
    expect(early.firstWhere((x) => x.date == d(6, 30)).spent, 999);
    expect(early.last.planned, 1000);
  });

  test('spending on a planned event is planned money, not the weekly allowance', () {
    final gift = Entry(id: ++_id, day: d(7, 15), isIncome: false, amount: 4500, categoryKey: 'food', event: EventLink(1, d(7, 20)));
    final i = insights(
      period: InsightsPeriod.week,
      today: d(7, 15),
      openingDate: d(7, 1),
      weeklyCap: 5000,
      entries: [...entries, gift],
      categories: demoCategories,
      rules: rules,
    );
    final without = run(InsightsPeriod.week);
    expect(i.flexibleOut, without.flexibleOut);
    expect(i.fixedOut, without.fixedOut + 4500);
    expect(flexibleSpent([gift], const {}, d(7, 15), d(7, 15)), 0);
  });

  test('a past week is whole: every day finished and the week counted', () {
    final i = insights(period: InsightsPeriod.week, offset: -1, today: d(7, 15), openingDate: d(7, 1), weeklyCap: 5000, entries: entries, categories: demoCategories, rules: rules);
    expect((i.from, i.to), (d(7, 6), d(7, 12)));
    expect((i.moneyOut, i.flexibleOut), (5000, 5000));
    expect((i.daysSoFar, i.zeroSpendDays), (7, 4));
    expect((i.weeksUnderAllowance, i.fullWeeks), (1, 1));
    expect(i.lastDays.last.date, d(7, 12));
  });

  test('a past month runs to its last day, starting no earlier than the first day logged', () {
    final i = insights(period: InsightsPeriod.month, offset: -1, today: d(7, 15), openingDate: d(7, 1), weeklyCap: 5000, entries: entries, categories: demoCategories, rules: rules);
    expect((i.from, i.to, i.moneyOut), (d(6, 30), d(6, 30), 999));
  });

  test('the way back stops at the week or month of the first day logged', () {
    expect(earliestOffset(InsightsPeriod.month, d(7, 15), d(6, 30)), -1);
    expect(earliestOffset(InsightsPeriod.week, d(7, 15), d(6, 30)), -2);
    expect(earliestOffset(InsightsPeriod.month, DateTime.utc(2027, 1, 9), d(10, 13)), -3);
    expect(periodSpan(InsightsPeriod.month, DateTime.utc(2027, 1, 9), d(10, 13), offset: -3), (d(10, 1), d(10, 31)));
  });
}
