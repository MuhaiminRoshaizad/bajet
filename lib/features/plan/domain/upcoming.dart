import 'plan_models.dart';

class UpcomingItem {
  const UpcomingItem({
    required this.date,
    required this.name,
    required this.signedAmount,
    this.lastDate,
    this.categoryKey,
    this.counted = true,
    this.isGoal = false,
    this.yearly = false,
    this.budget,
    this.spent = 0,
  });

  final DateTime date;

  /// The last day it may land, for a bill or income that moves around.
  final DateTime? lastDate;

  /// A bill's or income's category; null for one-off events and goals.
  final String? categoryKey;
  final String name;
  final int signedAmount;

  /// False for money the projection leaves out, such as an unconfirmed bonus.
  final bool counted;
  final bool isGoal;

  /// An event that comes back every year.
  final bool yearly;

  /// An event's budget once something is spent against it; [signedAmount]
  /// is then only what is left of it.
  final int? budget;
  final int spent;
}

/// Everything planned from [from] to [to] inclusive, soonest first: each
/// month's recurring items, planned events and goal purchases.
List<UpcomingItem> upcoming({
  required List<RecurringItem> recurring,
  required List<PlannedEvent> events,
  required List<Goal> goals,
  required DateTime from,
  required DateTime to,
}) {
  final items = <UpcomingItem>[
    for (final r in recurring.where((r) => r.active))
      for (var due = calendarDay(r.nextDue); !due.isAfter(to); due = DateTime.utc(due.year, due.month + 1, due.day))
        if (!due.isBefore(from))
          UpcomingItem(
            date: due,
            lastDate: r.windowDays == 0 ? null : DateTime.utc(due.year, due.month, due.day + r.windowDays),
            name: r.name,
            signedAmount: r.signedAmount,
            categoryKey: r.categoryKey,
          ),
    for (final e in events.where((e) => !e.done))
      for (final day in e.occurrences(from, to))
        UpcomingItem(
          date: day,
          name: e.name,
          signedAmount: day == calendarDay(e.date) ? e.signedOutstanding : e.signedAmount,
          budget: day == calendarDay(e.date) && e.spent > 0 ? e.amount : null,
          spent: day == calendarDay(e.date) ? e.spent : 0,
          counted: e.countInProjection,
          yearly: e.repeatsYearly,
        ),
    for (final g in goals.where((g) => !calendarDay(g.targetDate).isBefore(from) && !calendarDay(g.targetDate).isAfter(to)))
      UpcomingItem(date: calendarDay(g.targetDate), name: g.name, signedAmount: -g.price, isGoal: true),
  ];
  return items..sort((a, b) => a.date.compareTo(b.date));
}
