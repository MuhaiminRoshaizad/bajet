import 'dart:math' as math;

import 'plan_models.dart';

class ProjectedDay {
  const ProjectedDay(this.date, this.balance, this.balanceBeforeGoals);

  final DateTime date;
  final int balance;

  /// The balance that day before any goal is bought, so a chart can draw the
  /// drop on buy day as its own step.
  final int balanceBeforeGoals;
}

class GoalOutcome {
  const GoalOutcome(this.goal, this.leftAfterBuying, this.onTrack, {this.sums = RunwaySums.none});

  final Goal goal;
  final int leftAfterBuying;

  /// True when what is left after buying is at least the buffer.
  final bool onTrack;

  /// How [leftAfterBuying] was reached, from today to buy day.
  final RunwaySums sums;
}

/// The parts of a goal's outcome, all in sen and all positive: what is left
/// after buying is [balanceNow] − [dailySpending] + [income] − [costs] −
/// [earlierGoals] − the goal's price.
class RunwaySums {
  const RunwaySums({this.balanceNow = 0, this.dailySpending = 0, this.income = 0, this.costs = 0, this.earlierGoals = 0});

  final int balanceNow;

  /// The weekly rhythm's planned spending, day by day.
  final int dailySpending;

  /// Recurring and planned income that falls before or on buy day.
  final int income;

  /// Recurring bills, planned expenses and any what-if monthly cost.
  final int costs;

  /// Goals bought earlier on the way, or earlier the same day.
  final int earlierGoals;

  static const none = RunwaySums();
}

/// "What if" changes to the plan, tried out on Runway without being saved.
class WhatIf {
  const WhatIf({this.weeklyChange = 0, this.monthlyCost = 0, this.countUnconfirmed = false});

  /// Flexible spending added to (or, if negative, taken off) each week,
  /// spread over its seven days. A day never drops below zero.
  final int weeklyChange;

  /// A new cost on the 1st of every month after today, such as a subscription.
  final int monthlyCost;

  /// Also count planned income and expenses marked as not counted.
  final bool countUnconfirmed;

  static const none = WhatIf();

  bool get isNone => weeklyChange == 0 && monthlyCost == 0 && !countUnconfirmed;

  WhatIf copyWith({int? weeklyChange, int? monthlyCost, bool? countUnconfirmed}) => WhatIf(
        weeklyChange: weeklyChange ?? this.weeklyChange,
        monthlyCost: monthlyCost ?? this.monthlyCost,
        countUnconfirmed: countUnconfirmed ?? this.countUnconfirmed,
      );

  @override
  bool operator ==(Object other) =>
      other is WhatIf && other.weeklyChange == weeklyChange && other.monthlyCost == monthlyCost && other.countUnconfirmed == countUnconfirmed;

  @override
  int get hashCode => Object.hash(weeklyChange, monthlyCost, countUnconfirmed);
}

class Projection {
  const Projection(this.days, this.goals);

  final List<ProjectedDay> days;
  final List<GoalOutcome> goals;
}

/// Simulates the balance one day at a time, from today to the last goal's
/// target date, using only the plan: the weekly rhythm, recurring items,
/// planned events and goal prices. Real logs enter only through [balance] and
/// [flexSpentToday].
Projection project({
  required int balance,
  required DateTime today,
  required List<WeeklyRule> rules,
  required List<RecurringItem> recurring,
  required List<PlannedEvent> events,
  required List<Goal> goals,
  required int buffer,
  int flexSpentToday = 0,
  int horizonDaysWithoutGoal = 30,
  WhatIf whatIf = WhatIf.none,
}) {
  final start = calendarDay(today);
  final sortedGoals = [...goals]..sort((a, b) => a.priority.compareTo(b.priority));
  final end = sortedGoals.isEmpty
      ? DateTime.utc(start.year, start.month, start.day + horizonDaysWithoutGoal)
      : sortedGoals.map((g) => calendarDay(g.targetDate)).reduce((a, b) => a.isAfter(b) ? a : b);
  final change = spreadOverWeek(whatIf.weeklyChange.abs());
  final planned = {
    for (final r in rules) r.weekday: math.max(0, r.plannedSpend + whatIf.weeklyChange.sign * change[r.weekday - 1]),
  };

  final days = <ProjectedDay>[];
  final outcomes = <GoalOutcome>[];
  var running = balance;
  var spent = 0, income = 0, costs = 0, bought = 0;
  void move(int signed) {
    running += signed;
    if (signed > 0) {
      income += signed;
    } else {
      costs -= signed;
    }
  }

  // Each event on every day it happens in the window, yearly ones each year.
  final eventsOn = <DateTime, List<int>>{};
  for (final e in events) {
    if (e.done || !(e.countInProjection || whatIf.countUnconfirmed)) continue;
    // Spending already logged against this occurrence has left the
    // balance; only what is left of its budget is still to come.
    for (final day in e.occurrences(start, end)) {
      (eventsOn[day] ??= []).add(day == calendarDay(e.date) ? e.signedOutstanding : e.signedAmount);
    }
  }

  for (var day = start; !day.isAfter(end); day = DateTime.utc(day.year, day.month, day.day + 1)) {
    var spend = planned[day.weekday] ?? 0;
    // Today's logs already left the balance; only the unspent part of the plan remains.
    if (day == start) spend = (spend - flexSpentToday).clamp(0, spend);
    running -= spend;
    spent += spend;

    for (final item in recurring) {
      if (item.active && _dueOn(item, day)) move(item.signedAmount);
    }
    for (final amount in eventsOn[day] ?? const <int>[]) {
      move(amount);
    }
    if (day != start && day.day == 1) move(-whatIf.monthlyCost);

    final beforeGoals = running;
    for (final g in sortedGoals) {
      if (calendarDay(g.targetDate) == day) {
        running -= g.price;
        final sums = RunwaySums(balanceNow: balance, dailySpending: spent, income: income, costs: costs, earlierGoals: bought);
        outcomes.add(GoalOutcome(g, running, running >= buffer, sums: sums));
        bought += g.price;
      }
    }
    days.add(ProjectedDay(day, running, beforeGoals));
  }
  return Projection(days, outcomes);
}

/// Recurring items fall on the same day of each month from [RecurringItem.nextDue]
/// onward, moved to the end of their window when that is when they count.
/// Days of month are capped at 28, so every month has the day.
bool _dueOn(RecurringItem item, DateTime day) {
  final first = calendarDay(item.nextDue);
  final occurrence = DateTime.utc(day.year, day.month, day.day - item.countedAfter);
  return !occurrence.isBefore(first) && occurrence.day == first.day;
}
