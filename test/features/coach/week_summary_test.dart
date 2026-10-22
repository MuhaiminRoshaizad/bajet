import 'package:bajet/features/coach/domain/week_summary.dart';
import 'package:bajet/features/ledger/domain/ledger_models.dart';
import 'package:bajet/features/plan/domain/plan_models.dart';
import 'package:bajet/features/plan/domain/projection.dart';
import 'package:bajet/features/plan/domain/upcoming.dart';
import 'package:flutter_test/flutter_test.dart';

DateTime d(int y, int m, int day) => DateTime.utc(y, m, day);

const categories = [
  Category(key: 'food', label: 'Food', isIncome: false, tint: 'apricot', isFixed: false),
  Category(key: 'bills', label: 'Bills', isIncome: false, tint: 'teal', isFixed: true),
];

final rules = [for (var w = 1; w <= 7; w++) WeeklyRule(weekday: w, label: 'Day', type: DayType.spend, plannedSpend: 1000)];

String summary({List<Entry> entries = const [], Projection? projection, List<UpcomingItem> upcoming = const []}) => weekSummary(
      today: d(2026, 7, 1), // Wednesday
      balance: 150000,
      weeklyCap: 5000,
      buffer: 50000,
      entries: entries,
      categories: categories,
      rules: rules,
      projection: projection,
      upcoming: upcoming,
    );

void main() {
  test('covers the week, balance and allowance', () {
    final s = summary(entries: [Entry(id: 1, day: d(2026, 6, 29), isIncome: false, amount: 1200, categoryKey: 'food')]);
    expect(s, contains('week of 29/06/2026 to 05/07/2026'));
    expect(s, contains('Balance: RM1,500.00'));
    expect(s, contains('Spending on wants this week: RM12.00 of RM50.00 (RM38.00 left)'));
  });

  test("a need stays out of the allowance's figure and is named apart", () {
    final s = summary(entries: [
      Entry(id: 1, day: d(2026, 6, 29), isIncome: false, amount: 1200, categoryKey: 'food'),
      Entry(id: 2, day: d(2026, 6, 30), isIncome: false, amount: 4500, categoryKey: 'food', spendKind: SpendKind.need),
    ]);
    expect(s, contains('Spending on wants this week: RM12.00 of RM50.00 (RM38.00 left)'));
    expect(s, contains('Needs this week, kept out of the allowance: RM45.00'));
    expect(summary(), isNot(contains('Needs this week')));
  });

  test('lists categories by size and marks fixed ones', () {
    final s = summary(entries: [
      Entry(id: 1, day: d(2026, 6, 30), isIncome: false, amount: 900, categoryKey: 'food'),
      Entry(id: 2, day: d(2026, 6, 30), isIncome: false, amount: 4500, categoryKey: 'bills'),
    ]);
    expect(s.indexOf('- Bills: RM45.00 (fixed)'), lessThan(s.indexOf('- Food: RM9.00')));
  });

  test('names days that went over plan, and only those', () {
    final s = summary(entries: [Entry(id: 1, day: d(2026, 6, 30), isIncome: false, amount: 1500, categoryKey: 'food')]);
    expect(s, contains('- Tue 30/06: RM15.00 against RM10.00 planned'));
    expect(s, isNot(contains('Mon 29/06:')));
  });

  test('says so when nothing has happened yet', () {
    final s = summary();
    expect(s, contains('- Nothing spent yet'));
    expect(s, contains('Days over plan:\n- None'));
    expect(s, isNot(contains('Goal:')));
  });

  test('includes the goal outcome and what is coming up', () {
    final goal = Goal(id: 1, name: 'Laptop', price: 450000, targetDate: d(2026, 12, 1));
    final s = summary(
      projection: Projection(const [], [GoalOutcome(goal, 120000, true)]),
      upcoming: [
        UpcomingItem(date: d(2026, 7, 25), name: 'Salary', signedAmount: 300000),
        UpcomingItem(date: d(2026, 8, 1), name: 'Bonus', signedAmount: 50000, counted: false),
      ],
    );
    expect(s, contains('Goal: Laptop, RM4,500.00 on 01/12/2026'));
    expect(s, contains('Projected left after buying: RM1,200.00 (on track against a RM500.00 buffer)'));
    expect(s, contains('- 25/07/2026 Salary: +RM3,000.00'));
    expect(s, contains('- 01/08/2026 Bonus: +RM500.00 (not counted)'));
  });
}
