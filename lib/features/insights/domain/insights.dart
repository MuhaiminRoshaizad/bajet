import '../../ledger/domain/ledger_models.dart';
import '../../plan/domain/plan_models.dart';

enum InsightsPeriod { week, month, all }

/// A label the owner logs often, and what it usually costs.
class FrequentItem {
  const FrequentItem(this.label, this.count, this.average);

  final String label;
  final int count;
  final int average;
}

/// One day's flexible spending against that day's plan.
class DayAgainstPlan {
  const DayAgainstPlan(this.date, this.spent, this.planned);

  final DateTime date;
  final int spent;
  final int planned;

  bool get over => spent > planned;
}

/// Where the money went over a period, and the habits behind it. Amounts are
/// sen; every figure covers [from] to [to] inclusive.
class Insights {
  const Insights({
    required this.from,
    required this.to,
    required this.moneyIn,
    required this.moneyOut,
    required this.fixedOut,
    required this.flexibleOut,
    required this.untrackedOut,
    required this.flexibleByCategory,
    required this.outByCategory,
    required this.lastDays,
    required this.zeroSpendDays,
    required this.daysWithinPlan,
    required this.daysSoFar,
    required this.weeksUnderAllowance,
    required this.fullWeeks,
    required this.daysLogged,
    required this.frequent,
    required this.biggest,
  });

  final DateTime from;
  final DateTime to;
  final int moneyIn;
  final int moneyOut;

  /// Fixed spending, goal purchases included, untracked money excluded.
  final int fixedOut;
  final int flexibleOut;
  final int untrackedOut;

  /// Flexible spending per category key, largest first.
  final List<(String, int)> flexibleByCategory;

  /// All money out per category key, fixed and untracked included, largest
  /// first.
  final List<(String, int)> outByCategory;

  /// The fourteen days up to [to], oldest first, whatever the period. Days
  /// before the opening date carry no plan and no spending.
  final List<DayAgainstPlan> lastDays;

  final int zeroSpendDays;
  final int daysWithinPlan;
  final int daysSoFar;

  /// Monday-to-Sunday weeks wholly inside the period that stayed within the
  /// weekly allowance, out of [fullWeeks].
  final int weeksUnderAllowance;
  final int fullWeeks;

  /// Days with at least one entry.
  final int daysLogged;
  final FrequentItem? frequent;

  /// The largest single flexible spend.
  final Entry? biggest;

  int get kept => moneyIn - moneyOut;
  bool get isEmpty => moneyIn == 0 && moneyOut == 0;
}

/// The first and last day of the week or month [offset] steps before the
/// one holding [today] (0 is the current one), never past today. "All" runs
/// from [firstDay] to today, whatever the offset.
(DateTime, DateTime) periodSpan(InsightsPeriod period, DateTime today, DateTime firstDay, {int offset = 0}) {
  final to = calendarDay(today);
  final (from, end) = switch (period) {
    InsightsPeriod.week => (weekStart(to).add(Duration(days: 7 * offset)), weekStart(to).add(Duration(days: 7 * offset + 6))),
    InsightsPeriod.month => (DateTime.utc(to.year, to.month + offset, 1), DateTime.utc(to.year, to.month + offset + 1, 0)),
    InsightsPeriod.all => (calendarDay(firstDay), to),
  };
  return (from, end.isAfter(to) ? to : end);
}

/// How far back [period] can step: the offset of the week or month holding
/// [firstDay], so there is always something it could show.
int earliestOffset(InsightsPeriod period, DateTime today, DateTime firstDay) => switch (period) {
      InsightsPeriod.week => -(weekStart(calendarDay(today)).difference(weekStart(calendarDay(firstDay))).inDays ~/ 7),
      InsightsPeriod.month => -((today.year - firstDay.year) * 12 + today.month - firstDay.month),
      InsightsPeriod.all => 0,
    };

/// The first day Insights knows about: the opening date, or an earlier day
/// the owner logged after setting up, such as a meal they forgot. Those
/// count as spending; only the balance leaves them out, since the starting
/// balance already had them taken off (docs/decisions.md 020).
DateTime firstDay(DateTime openingDate, List<Entry> entries) =>
    entries.fold(calendarDay(openingDate), (first, e) => e.day.isBefore(first) ? calendarDay(e.day) : first);

/// The figures for [period], [offset] weeks or months back from the current
/// one.
Insights insights({
  required InsightsPeriod period,
  int offset = 0,
  required DateTime today,
  required DateTime openingDate,
  required int weeklyCap,
  required List<Entry> entries,
  required List<Category> categories,
  required List<WeeklyRule> rules,
}) {
  final now = calendarDay(today);
  final first = firstDay(openingDate, entries);
  var (from, to) = periodSpan(period, now, first, offset: offset);
  // Nothing before the first day counts, whatever the period.
  if (from.isBefore(first)) from = first;
  final fixed = {for (final c in categories.where((c) => c.isFixed)) c.key};
  final planned = {for (final r in rules) r.weekday: r.plannedSpend};
  bool inRange(DateTime d) => !d.isBefore(from) && !d.isAfter(to);
  final inPeriod = entries.where((e) => inRange(e.day)).toList();
  final out = inPeriod.where((e) => !e.isIncome).toList();
  final flexible = out.where((e) => e.isFlexible(fixed)).toList();

  int sum(Iterable<Entry> es) => es.fold(0, (s, e) => s + e.amount);

  List<(String, int)> byCategory(Iterable<Entry> es) {
    final totals = <String, int>{};
    for (final e in es) {
      totals[e.categoryKey] = (totals[e.categoryKey] ?? 0) + e.amount;
    }
    return totals.entries.map((e) => (e.key, e.value)).toList()..sort((a, b) => b.$2.compareTo(a.$2));
  }

  final days = [for (var d = from; !d.isAfter(to); d = DateTime.utc(d.year, d.month, d.day + 1)) d];
  int spentOn(DateTime d) => d.isBefore(first) ? 0 : flexibleSpent(entries, fixed, d, d);
  // Today is still under way, so it counts toward no habit yet; a past
  // period is finished throughout.
  final finished = days.where((d) => d != now).toList();

  var weeksUnder = 0, fullWeeks = 0;
  for (var monday = weekStart(from); !monday.isAfter(to); monday = DateTime.utc(monday.year, monday.month, monday.day + 7)) {
    final sunday = DateTime.utc(monday.year, monday.month, monday.day + 6);
    if (monday.isBefore(from) || sunday.isAfter(to) || !sunday.isBefore(now)) continue;
    fullWeeks++;
    if (flexibleSpent(entries, fixed, monday, sunday) <= weeklyCap) weeksUnder++;
  }

  final byLabel = <String, List<int>>{};
  for (final e in flexible.where((e) => e.label != null)) {
    byLabel.putIfAbsent(e.label!, () => []).add(e.amount);
  }
  final top = byLabel.entries.where((e) => e.value.length > 1).fold<MapEntry<String, List<int>>?>(
        null,
        (best, e) => best == null || e.value.length > best.value.length ? e : best,
      );

  return Insights(
    from: from,
    to: to,
    moneyIn: sum(inPeriod.where((e) => e.isIncome)),
    moneyOut: sum(out),
    // Planned money: bills, goals, and anything spent on a planned event.
    fixedOut: sum(out.where((e) => !e.isFlexible(fixed) && e.categoryKey != untrackedCategoryKey)),
    flexibleOut: sum(flexible),
    untrackedOut: sum(out.where((e) => e.categoryKey == untrackedCategoryKey)),
    flexibleByCategory: byCategory(flexible),
    outByCategory: byCategory(out),
    lastDays: [
      for (var i = 13; i >= 0; i--)
        () {
          final d = DateTime.utc(to.year, to.month, to.day - i);
          return DayAgainstPlan(d, spentOn(d), d.isBefore(first) ? 0 : planned[d.weekday] ?? 0);
        }(),
    ],
    zeroSpendDays: finished.where((d) => spentOn(d) == 0).length,
    daysWithinPlan: finished.where((d) => spentOn(d) <= (planned[d.weekday] ?? 0)).length,
    daysSoFar: finished.length,
    weeksUnderAllowance: weeksUnder,
    fullWeeks: fullWeeks,
    daysLogged: {for (final e in inPeriod) e.day}.length,
    frequent: top == null ? null : FrequentItem(top.key, top.value.length, (top.value.reduce((a, b) => a + b) / top.value.length).round()),
    biggest: flexible.isEmpty ? null : flexible.reduce((a, b) => b.amount > a.amount ? b : a),
  );
}
