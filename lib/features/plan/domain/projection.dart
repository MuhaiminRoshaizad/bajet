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
  const GoalOutcome(this.goal, this.leftAfterBuying, this.onTrack);

  final Goal goal;
  final int leftAfterBuying;

  /// True when what is left after buying is at least the buffer.
  final bool onTrack;
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

  for (var day = start; !day.isAfter(end); day = DateTime.utc(day.year, day.month, day.day + 1)) {
    var spend = planned[day.weekday] ?? 0;
    // Today's logs already left the balance; only the unspent part of the plan remains.
    if (day == start) spend = (spend - flexSpentToday).clamp(0, spend);
    running -= spend;

    for (final item in recurring) {
      if (item.active && _dueOn(item, day)) running += item.signedAmount;
    }
    for (final e in events) {
      if (!e.done && (e.countInProjection || whatIf.countUnconfirmed) && calendarDay(e.date) == day) running += e.signedAmount;
    }
    if (day != start && day.day == 1) running -= whatIf.monthlyCost;

    final beforeGoals = running;
    for (final g in sortedGoals) {
      if (calendarDay(g.targetDate) == day) {
        running -= g.price;
        outcomes.add(GoalOutcome(g, running, running >= buffer));
      }
    }
    days.add(ProjectedDay(day, running, beforeGoals));
  }
  return Projection(days, outcomes);
}

/// Recurring items fall on the same day of each month from [RecurringItem.nextDue]
/// onward. Days of month are capped at 28, so every month has the day.
bool _dueOn(RecurringItem item, DateTime day) {
  final first = calendarDay(item.nextDue);
  return !day.isBefore(first) && day.day == first.day;
}
