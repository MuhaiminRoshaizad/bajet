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
}) {
  final start = calendarDay(today);
  final sortedGoals = [...goals]..sort((a, b) => a.priority.compareTo(b.priority));
  final end = sortedGoals.isEmpty
      ? DateTime.utc(start.year, start.month, start.day + horizonDaysWithoutGoal)
      : sortedGoals.map((g) => calendarDay(g.targetDate)).reduce((a, b) => a.isAfter(b) ? a : b);
  final planned = {for (final r in rules) r.weekday: r.plannedSpend};

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
      if (!e.done && e.countInProjection && calendarDay(e.date) == day) running += e.signedAmount;
    }

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
