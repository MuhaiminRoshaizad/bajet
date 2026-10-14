import 'package:bajet/features/insights/domain/insights.dart';
import 'package:bajet/features/ledger/domain/ledger_models.dart';
import 'package:bajet/features/plan/domain/plan_models.dart';
import 'package:bajet/features/plan/domain/projection.dart';
import 'package:bajet/features/report/domain/report.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_repositories.dart';

// Demo figures only.
DateTime d(int m, int day) => DateTime.utc(2026, m, day);
final categories = {for (final c in demoCategories) c.key: c};
final rules = [for (var w = 1; w <= 7; w++) WeeklyRule(weekday: w, label: 'Day', type: DayType.spend, plannedSpend: 1000)];
final entries = [
  Entry(id: 1, day: d(7, 1), isIncome: true, amount: 300000, categoryKey: 'salary', label: 'Salary'),
  Entry(id: 2, day: d(7, 2), isIncome: false, amount: 800, categoryKey: 'food', label: 'Lunch', note: 'With team, then "coffee"'),
  Entry(id: 3, day: d(7, 3), isIncome: false, amount: 50000, categoryKey: 'bills', label: 'Rent'),
];
Insights month() => insights(
      period: InsightsPeriod.month,
      today: d(7, 3),
      openingDate: d(7, 1),
      weeklyCap: 5000,
      entries: entries,
      categories: demoCategories,
      rules: rules,
    );

void main() {
  test('the text report covers totals, categories and the goal', () {
    final goal = GoalOutcome(Goal(id: 1, name: 'Laptop', price: 450000, targetDate: d(10, 1)), 420000, true);
    final text = reportText(i: month(), balance: 249200, weeklyCap: 5000, buffer: 50000, categories: categories, goal: goal);
    expect(text, startsWith('bajet report, 01/07/2026 to 03/07/2026\n'));
    expect(text, contains('Money out: RM508.00'));
    expect(text, contains('Kept: RM2,492.00 (83% of what came in)'));
    expect(text, contains('- Food: RM8.00'));
    expect(text, contains('- 2 of 2 days within plan'));
    expect(text, contains('Projected left after buying: RM4,200.00 (on track against a RM500.00 buffer)'));
  });

  test('the CSV has one row per entry, oldest first, quoted where needed', () {
    final csv = reportCsv(entriesIn(month(), entries.reversed.toList()), categories);
    expect(csv.split('\r\n'), [
      'date,type,category,label,note,amount',
      '2026-07-01,income,Salary,Salary,,3000.00',
      '2026-07-02,expense,Food,Lunch,"With team, then ""coffee""",8.00',
      '2026-07-03,expense,Bills,Rent,,500.00',
      '',
    ]);
  });
}
