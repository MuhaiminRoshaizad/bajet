/// Plan inputs. Amounts are integer sen; dates are calendar days held as UTC
/// midnight so day arithmetic never crosses a daylight-saving boundary.
library;

import 'dart:math' as math;

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

/// The longest window a monthly item may land in: short enough that one
/// month's window always ends before the next one opens.
const maxWindowDays = 27;

/// A monthly bill or income. [nextDue] is the next occurrence not yet paid;
/// confirming one moves it forward a month.
class RecurringItem {
  const RecurringItem({
    required this.id,
    required this.name,
    required this.amount,
    required this.categoryKey,
    required this.isIncome,
    required this.nextDue,
    this.windowDays = 0,
    this.active = true,
    this.accountId,
  });

  final int id;
  final String name;
  final int amount;
  final String categoryKey;
  final bool isIncome;
  final DateTime nextDue;

  /// The account it is paid from or into; null means the first account.
  final int? accountId;

  /// Days after [nextDue] it may still land; 0 for a fixed day.
  final int windowDays;
  final bool active;

  int get signedAmount => isIncome ? amount : -amount;

  /// The last day the next occurrence may land.
  DateTime get windowEnd => DateTime.utc(nextDue.year, nextDue.month, nextDue.day + windowDays);

  /// How many days after its due day the projection counts it: income on
  /// the last day it may arrive and bills on the first day they may go, so
  /// the plan never leans on money coming early or a bill coming late.
  int get countedAfter => isIncome ? windowDays : 0;

  RecurringItem copyWith({String? name, int? amount, String? categoryKey, DateTime? nextDue, int? windowDays, bool? active}) => RecurringItem(
        id: id,
        name: name ?? this.name,
        amount: amount ?? this.amount,
        categoryKey: categoryKey ?? this.categoryKey,
        isIncome: isIncome,
        nextDue: nextDue ?? this.nextDue,
        windowDays: windowDays ?? this.windowDays,
        active: active ?? this.active,
        accountId: accountId,
      );
}

/// What [PlanRepository.deleteRecurring] took away, kept so it can be put
/// back: the item, and the confirmed entries that pointed at it.
class RecurringRemoval {
  const RecurringRemoval(this.item, this.linkedEntryIds);

  final RecurringItem item;
  final List<int> linkedEntryIds;
}

/// What [PlanRepository.deleteEvent] took away, kept so it can be put back:
/// the event, and the entries that were spent on it.
class EventRemoval {
  const EventRemoval(this.event, this.linkedEntryIds);

  final PlannedEvent event;
  final List<int> linkedEntryIds;
}

/// A one-off future income or expense, such as a birthday or a payment.
class PlannedEvent {
  const PlannedEvent({
    required this.id,
    required this.name,
    required this.amount,
    required this.categoryKey,
    required this.isIncome,
    required this.date,
    this.countInProjection = true,
    this.done = false,
    this.repeatsYearly = false,
    this.spent = 0,
  });

  final int id;
  final String name;
  final int amount;
  final String categoryKey;
  final bool isIncome;

  /// The next time it happens; for a yearly event, the next year's date.
  final DateTime date;

  /// False for money that may not arrive, such as an unconfirmed bonus.
  final bool countInProjection;
  final bool done;

  /// Comes back on the same date every year, such as a birthday.
  final bool repeatsYearly;

  /// What has been logged against this occurrence. For an expense, [amount]
  /// is a budget and this is how much of it is used.
  final int spent;

  int get signedAmount => isIncome ? amount : -amount;

  /// What is still to come for this occurrence: an expense's budget less
  /// what is already logged against it, which has left the balance already.
  int get outstanding => isIncome ? amount : (amount - spent).clamp(0, amount);

  int get signedOutstanding => isIncome ? outstanding : -outstanding;

  /// The days it happens from [from] to [to] inclusive: once, or every year
  /// from [date] on. A 29 February falls on 1 March in other years.
  List<DateTime> occurrences(DateTime from, DateTime to) {
    final first = calendarDay(date);
    final days = repeatsYearly ? [for (var y = 0; !DateTime.utc(first.year + y, first.month, first.day).isAfter(to); y++) DateTime.utc(first.year + y, first.month, first.day)] : [first];
    return [for (final d in days) if (!d.isBefore(from) && !d.isAfter(to)) d];
  }

  PlannedEvent copyWith({String? name, int? amount, String? categoryKey, DateTime? date, bool? countInProjection, bool? done, bool? repeatsYearly}) => PlannedEvent(
        id: id,
        name: name ?? this.name,
        amount: amount ?? this.amount,
        categoryKey: categoryKey ?? this.categoryKey,
        isIncome: isIncome,
        date: date ?? this.date,
        countInProjection: countInProjection ?? this.countInProjection,
        done: done ?? this.done,
        repeatsYearly: repeatsYearly ?? this.repeatsYearly,
        spent: spent,
      );
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

  Goal copyWith({String? name, int? price, DateTime? targetDate}) =>
      Goal(id: id, name: name ?? this.name, price: price ?? this.price, targetDate: targetDate ?? this.targetDate, priority: priority, achievedOn: achievedOn);
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
///
/// Days that were an even split (no more than a sen apart) are split evenly
/// again, so the result never depends on the order days were switched off;
/// amounts the owner typed unevenly keep their shape and only share the
/// freed amount.
List<WeeklyRule> withRule(List<WeeklyRule> rules, WeeklyRule changed) {
  final before = rules.firstWhere((r) => r.weekday == changed.weekday);
  final freed = changed.type == DayType.zero ? before.plannedSpend - changed.plannedSpend : 0;
  final receivers = [for (final r in rules) if (r.weekday != changed.weekday && r.type != DayType.zero) r];
  if (freed <= 0 || receivers.isEmpty) return [for (final r in rules) r.weekday == changed.weekday ? changed : r];

  final amounts = [for (final r in receivers) r.plannedSpend];
  final even = amounts.reduce(math.max) - amounts.reduce(math.min) <= 1;
  final total = amounts.fold(0, (s, a) => s + a) + freed;
  final shares = even ? spreadEvenly(total, receivers.length) : [for (final (i, s) in spreadEvenly(freed, receivers.length).indexed) amounts[i] + s];
  final next = {for (final (i, r) in receivers.indexed) r.weekday: shares[i]};
  return [
    for (final r in rules)
      if (r.weekday == changed.weekday) changed else if (next.containsKey(r.weekday)) r.copyWith(plannedSpend: next[r.weekday]) else r,
  ];
}

/// Each spending day's even share of [weekly]; no-spending days keep RM0.
List<WeeklyRule> spreadOverSpendingDays(List<WeeklyRule> rules, int weekly) {
  final spending = [for (final r in rules) if (r.type != DayType.zero) r.weekday];
  final shares = spreadEvenly(weekly, spending.isEmpty ? 1 : spending.length);
  return [for (final r in rules) r.copyWith(plannedSpend: r.type == DayType.zero ? 0 : shares[spending.indexOf(r.weekday)])];
}
