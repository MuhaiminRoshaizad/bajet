/// Plan inputs. Amounts are integer sen; dates are calendar days held as UTC
/// midnight so day arithmetic never crosses a daylight-saving boundary.
library;

enum DayType { zero, spend, flex }

/// One weekday of the spending rhythm. [weekday] follows [DateTime.weekday]:
/// 1 is Monday.
class WeeklyRule {
  const WeeklyRule({
    required this.weekday,
    required this.label,
    required this.type,
    required this.plannedSpend,
    this.isFastingDay = false,
  });

  final int weekday;
  final String label;
  final DayType type;
  final int plannedSpend;
  final bool isFastingDay;
}

/// A monthly bill or income. [nextDue] is the next occurrence not yet paid;
/// confirming one moves it forward a month.
class RecurringItem {
  const RecurringItem({
    required this.id,
    required this.name,
    required this.amount,
    required this.isIncome,
    required this.nextDue,
    this.active = true,
  });

  final int id;
  final String name;
  final int amount;
  final bool isIncome;
  final DateTime nextDue;
  final bool active;

  int get signedAmount => isIncome ? amount : -amount;
}

/// A one-off future income or expense, such as a birthday or a payment.
class PlannedEvent {
  const PlannedEvent({
    required this.id,
    required this.name,
    required this.amount,
    required this.isIncome,
    required this.date,
    this.countInProjection = true,
    this.done = false,
  });

  final int id;
  final String name;
  final int amount;
  final bool isIncome;
  final DateTime date;

  /// False for money that may not arrive, such as an unconfirmed bonus.
  final bool countInProjection;
  final bool done;

  int get signedAmount => isIncome ? amount : -amount;
}

class Goal {
  const Goal({
    required this.id,
    required this.name,
    required this.price,
    required this.targetDate,
    this.priority = 1,
    this.achievedOn,
  });

  final int id;
  final String name;
  final int price;
  final DateTime targetDate;

  /// Lower runs first when two goals fall on the same day.
  final int priority;

  /// The day it was marked bought; null while it is still being saved for.
  final DateTime? achievedOn;
}

DateTime calendarDay(DateTime d) => DateTime.utc(d.year, d.month, d.day);

/// Splits a weekly amount into seven daily ones, Monday first, that add back
/// up to it exactly; leftover sen go to the earliest days.
List<int> spreadOverWeek(int weekly) => [for (var i = 0; i < 7; i++) weekly ~/ 7 + (i < weekly % 7 ? 1 : 0)];
