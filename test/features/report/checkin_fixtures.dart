import 'package:bajet/features/checkin/domain/checkin.dart';
import 'package:bajet/features/ledger/domain/ledger_models.dart';
import 'package:bajet/features/plan/domain/plan_models.dart';
import 'package:bajet/features/plan/domain/projection.dart';
import 'package:bajet/features/report/domain/weekly_checkin.dart';

// Demo figures only.
DateTime d(int m, int day, [int y = 2026]) => DateTime.utc(y, m, day);

const categories = [
  Category(key: 'food', label: 'Food', isIncome: false, tint: 'apricot', isFixed: false),
  Category(key: 'transport', label: 'Transport', isIncome: false, tint: 'sky', isFixed: false),
  Category(key: 'bills', label: 'Bills', isIncome: false, tint: 'teal', isFixed: true),
  Category(key: untrackedCategoryKey, label: 'Untracked', isIncome: false, tint: 'neutral', isFixed: true),
  Category(key: 'salary', label: 'Salary', isIncome: true, tint: 'sage', isFixed: true),
];

// RM30.00 a week: Monday a fasting day, Thursday flexible, Saturday no spending.
const rules = [
  WeeklyRule(weekday: 1, label: 'Fast', type: DayType.spend, plannedSpend: 300, isFastingDay: true),
  WeeklyRule(weekday: 2, label: 'Workday', type: DayType.spend, plannedSpend: 600),
  WeeklyRule(weekday: 3, label: 'Workday', type: DayType.spend, plannedSpend: 600),
  WeeklyRule(weekday: 4, label: 'Flex', type: DayType.flex, plannedSpend: 900),
  WeeklyRule(weekday: 5, label: 'Workday', type: DayType.spend, plannedSpend: 600),
  WeeklyRule(weekday: 6, label: 'Rest', type: DayType.zero, plannedSpend: 0),
  WeeklyRule(weekday: 7, label: 'Rest', type: DayType.spend, plannedSpend: 0),
];

final recurring = [
  RecurringItem(id: 1, name: 'Salary', amount: 238445, categoryKey: 'salary', isIncome: true, nextDue: d(11, 1)),
  RecurringItem(id: 2, name: 'Bills', amount: 183989, categoryKey: 'bills', isIncome: false, nextDue: d(11, 1)),
];
final events = [
  PlannedEvent(id: 1, name: 'Birthday dinner', amount: 10000, categoryKey: 'food', isIncome: false, date: d(10, 30)),
  PlannedEvent(id: 2, name: 'Bonus', amount: 30000, categoryKey: 'salary', isIncome: true, date: d(12, 1), countInProjection: false),
];
final goals = [Goal(id: 1, name: 'Laptop', price: 300000, targetDate: d(1, 9, 2027))];

var _id = 0;
Entry spend(DateTime day, int amount, String category, [String? label]) =>
    Entry(id: ++_id, day: day, isIncome: false, amount: amount, categoryKey: category, label: label);

final sunday = d(10, 25);

WeeklyCheckin checkin({
  required List<Entry> entries,
  List<Checkin> checkins = const [],
  int balance = 401745,
  DateTime? opening,
  DateTime? today,
  List<RecurringItem>? recurringItems,
}) {
  final day = today ?? sunday;
  Projection run(WhatIf whatIf) => project(
        balance: balance,
        today: day,
        rules: rules,
        recurring: recurringItems ?? recurring,
        events: events,
        goals: goals,
        buffer: 100000,
        through: DateTime.utc(day.year, day.month, day.day + 7),
        whatIf: whatIf,
      );
  return weeklyCheckin(
    today: day,
    openingDate: opening ?? d(10, 12),
    weeklyCap: 3000,
    buffer: 100000,
    balance: balance,
    entries: entries,
    categories: categories,
    rules: rules,
    checkins: checkins,
    projection: run(WhatIf.none),
    unconfirmed: run(const WhatIf(countUnconfirmed: true)),
    recurring: recurringItems ?? recurring,
    events: events,
    goals: goals,
  );
}

final lastWeek = Checkin(checkedOn: d(10, 18), balance: 403000, matched: true, allowanceSpent: 2400, leftAfterBuying: 170000, nextTarget: 392000);

final week = [
  spend(d(10, 20), 550, 'food', 'Lunch'),
  spend(d(10, 21), 400, 'food', 'Coffee'),
  spend(d(10, 22), 600, 'transport', 'Fuel'),
  spend(d(10, 23), 600, 'food', 'Dinner'),
];
