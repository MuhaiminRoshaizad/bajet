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
    expect(amounts(noSaturday), [500, 500, 500, 500, 500, 0, 500]);

    final noWeekend = withRule(noSaturday, noSpending(7));
    expect(amounts(noWeekend), [600, 600, 600, 600, 600, 0, 0]);
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

  test('switching days off gives the same even split whatever the order', () {
    // Monday, Friday, Saturday and Sunday off leaves RM30 over three days.
    List<List<int>> orders(List<int> days) => days.length <= 1
        ? [days]
        : [for (final d in days) for (final rest in orders([...days]..remove(d))) [d, ...rest]];
    for (final order in orders([1, 5, 6, 7])) {
      var rules = week(spreadOverWeek(3000));
      for (final d in order) {
        rules = withRule(rules, noSpending(d));
      }
      expect(amounts(rules), [0, 1000, 1000, 1000, 0, 0, 0], reason: 'order $order');
    }
  });

  test('amounts typed unevenly keep their shape and only share what is freed', () {
    final rules = week([1500, 500, 500, 500, 500, 0, 0], zero: {6, 7});
    expect(amounts(withRule(rules, noSpending(5))), [1625, 625, 625, 625, 0, 0, 0]);
  });

  test('a no-spending day that starts spending takes its share from the others, so the week keeps its total', () {
    // RM40 over Tuesday to Friday, Monday off; Monday comes back at its share.
    final rules = week([0, 1000, 1000, 1000, 1000, 0, 0], zero: {1, 6, 7});
    expect(startingShare(rules, 1, 4000), 800);
    final monday = WeeklyRule(weekday: 1, label: 'Day', type: DayType.spend, plannedSpend: 800);
    expect(amounts(withRule(rules, monday)), [800, 800, 800, 800, 800, 0, 0]);
  });

  test('a day starting with an amount of its own takes that much, never leaving a day below zero', () {
    final rules = week([0, 1500, 300, 0, 0, 0, 0], zero: {1, 4, 5, 6, 7});
    final monday = WeeklyRule(weekday: 1, label: 'Day', type: DayType.spend, plannedSpend: 1000);
    expect(amounts(withRule(rules, monday)), [1000, 800, 0, 0, 0, 0, 0]);
  });

  test('with no other day planning anything, a day starts at the whole allowance', () {
    final rules = week(List.filled(7, 0), zero: {1, 2, 3, 4, 5, 6, 7});
    expect(startingShare(rules, 3, 4000), 4000);
    final wednesday = WeeklyRule(weekday: 3, label: 'Day', type: DayType.spend, plannedSpend: 4000);
    expect(amounts(withRule(rules, wednesday)), [0, 0, 4000, 0, 0, 0, 0]);
  });

  test('a yearly event happens on its date every year in the window, a one-off once', () {
    final birthday = PlannedEvent(id: 1, name: 'Birthday', amount: 10000, categoryKey: 'gifts', isIncome: false, date: DateTime.utc(2026, 10, 30), repeatsYearly: true);
    expect(birthday.occurrences(DateTime.utc(2026, 7, 1), DateTime.utc(2028, 12, 31)), [DateTime.utc(2026, 10, 30), DateTime.utc(2027, 10, 30), DateTime.utc(2028, 10, 30)]);
    expect(birthday.copyWith(repeatsYearly: false).occurrences(DateTime.utc(2026, 7, 1), DateTime.utc(2028, 12, 31)), [DateTime.utc(2026, 10, 30)]);
    expect(birthday.occurrences(DateTime.utc(2026, 11, 1), DateTime.utc(2027, 10, 29)), isEmpty);
  });

  test('a yearly event on 29 February falls on 1 March in other years', () {
    final leap = PlannedEvent(id: 1, name: 'Leap', amount: 100, categoryKey: 'gifts', isIncome: false, date: DateTime.utc(2028, 2, 29), repeatsYearly: true);
    expect(leap.occurrences(DateTime.utc(2028, 1, 1), DateTime.utc(2029, 12, 31)), [DateTime.utc(2028, 2, 29), DateTime.utc(2029, 3, 1)]);
  });
}
