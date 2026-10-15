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

  WeeklyRule copyWith({int? plannedSpend}) =>
      WeeklyRule(weekday: weekday, label: label, type: type, plannedSpend: plannedSpend ?? this.plannedSpend, isFastingDay: isFastingDay);
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

/// Splits [total] sen into [parts] shares that add back up to it exactly;
/// leftover sen go to the earliest shares.
List<int> spreadEvenly(int total, int parts) => [for (var i = 0; i < parts; i++) total ~/ parts + (i < total % parts ? 1 : 0)];

/// Splits a weekly amount into seven daily ones, Monday first.
List<int> spreadOverWeek(int weekly) => spreadEvenly(weekly, 7);

/// The rhythm once [changed] replaces its weekday. A day that becomes a
/// no-spending day hands what it had planned to the days that still spend,
/// so the week keeps its total; any other change is taken as typed.
List<WeeklyRule> withRule(List<WeeklyRule> rules, WeeklyRule changed) {
  final before = rules.firstWhere((r) => r.weekday == changed.weekday);
  final freed = changed.type == DayType.zero ? before.plannedSpend - changed.plannedSpend : 0;
  final receivers = [for (final r in rules) if (r.weekday != changed.weekday && r.type != DayType.zero) r.weekday];
  final shares = freed > 0 && receivers.isNotEmpty ? spreadEvenly(freed, receivers.length) : const <int>[];
  return [
    for (final r in rules)
      if (r.weekday == changed.weekday)
        changed
      else if (shares.isNotEmpty && receivers.contains(r.weekday))
        r.copyWith(plannedSpend: r.plannedSpend + shares[receivers.indexOf(r.weekday)])
      else
        r,
  ];
}

/// Each spending day's even share of [weekly]; no-spending days keep RM0.
List<WeeklyRule> spreadOverSpendingDays(List<WeeklyRule> rules, int weekly) {
  final spending = [for (final r in rules) if (r.type != DayType.zero) r.weekday];
  final shares = spreadEvenly(weekly, spending.isEmpty ? 1 : spending.length);
  return [for (final r in rules) r.copyWith(plannedSpend: r.type == DayType.zero ? 0 : shares[spending.indexOf(r.weekday)])];
}
