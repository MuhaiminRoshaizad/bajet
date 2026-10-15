import 'package:bajet/features/plan/domain/plan_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a weekly amount spreads over seven days and adds back up exactly', () {
    expect(spreadOverWeek(3500), [500, 500, 500, 500, 500, 500, 500]);
    expect(spreadOverWeek(3000), [429, 429, 429, 429, 428, 428, 428]);
    expect(spreadOverWeek(3000).reduce((a, b) => a + b), 3000);
    expect(spreadOverWeek(0), List.filled(7, 0));
  });

  List<WeeklyRule> week(List<int> amounts, {Set<int> zero = const {}}) => [
        for (var w = 1; w <= 7; w++)
          WeeklyRule(weekday: w, label: 'Day', type: zero.contains(w) ? DayType.zero : DayType.spend, plannedSpend: amounts[w - 1]),
      ];
  List<int> amounts(List<WeeklyRule> rules) => [for (final r in rules) r.plannedSpend];
  WeeklyRule noSpending(int weekday) => WeeklyRule(weekday: weekday, label: 'Weekend', type: DayType.zero, plannedSpend: 0);

  test('a day that stops spending hands its plan to the days that still spend', () {
    final rules = week(spreadOverWeek(3000));
    final noSaturday = withRule(rules, noSpending(6));
    expect(amounts(noSaturday), [501, 501, 500, 500, 499, 0, 499]);

    final noWeekend = withRule(noSaturday, noSpending(7));
    expect(amounts(noWeekend), [601, 601, 600, 600, 598, 0, 0]);
    expect(amounts(noWeekend).reduce((a, b) => a + b), 3000);
  });

  test('any other change to a day is kept as typed and moves nothing', () {
    final rules = week(spreadOverWeek(3000));
    final changed = withRule(rules, WeeklyRule(weekday: 1, label: 'Day', type: DayType.spend, plannedSpend: 1000));
    expect(amounts(changed), [1000, 429, 429, 429, 428, 428, 428]);
  });

  test('with no other spending day the freed plan simply goes', () {
    final rules = week([0, 0, 0, 0, 0, 0, 700], zero: {1, 2, 3, 4, 5, 6});
    expect(amounts(withRule(rules, noSpending(7))), List.filled(7, 0));
  });

  test('the allowance can be spread again over the spending days only', () {
    final rules = week([0, 0, 0, 0, 0, 0, 0], zero: {6, 7});
    expect(amounts(spreadOverSpendingDays(rules, 3000)), [600, 600, 600, 600, 600, 0, 0]);
  });
}
