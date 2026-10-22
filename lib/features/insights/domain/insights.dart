import '../../ledger/domain/ledger_models.dart';
import '../../plan/domain/plan_models.dart';

enum InsightsPeriod { week, month, all }

/// The parts money out splits into: what the plan counted already (bills,
/// goals, planned events), the day-to-day wants and needs, and money found
/// missing at a check-in.
enum OutPart { planned, wants, needs, untracked }

/// A label the user logs often, and what it usually costs.
class FrequentItem {
  const FrequentItem(this.label, this.count, this.average);

  final String label;
  final int count;
  final int average;
}

/// One day's spending on wants against that day's plan.
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
    required this.period,
    required this.from,
    required this.to,
    required this.moneyIn,
    required this.moneyOut,
    required this.outParts,
    required this.wantsByCategory,
    required this.outByCategory,
    required this.outEntries,
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

  final InsightsPeriod period;
  final DateTime from;
  final DateTime to;
  final int moneyIn;
  final int moneyOut;

  /// Every entry of money out in each part, newest first.
  final Map<OutPart, List<Entry>> outParts;

  int outOf(OutPart part) => (outParts[part] ?? const []).fold(0, (s, e) => s + e.amount);

  /// Fixed spending, goal purchases included, untracked money excluded.
  int get fixedOut => outOf(OutPart.planned);

  /// Day-to-day spending, wants and needs together.
  int get flexibleOut => outOf(OutPart.wants) + outOf(OutPart.needs);
  int get untrackedOut => outOf(OutPart.untracked);

  /// Spending on wants per category key, largest first.
  final List<(String, int)> wantsByCategory;

  /// All money out per category key, fixed and untracked included, largest
  /// first.
  final List<(String, int)> outByCategory;

  /// Every entry of money out behind [outByCategory], newest first, so a
  /// category can show what it was spent on.
  final List<Entry> outEntries;

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
/// the user logged after setting up, such as a meal they forgot. Those
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
  final wants = flexible.where((e) => e.spendKind == SpendKind.want).toList();

  int sum(Iterable<Entry> es) => es.fold(0, (s, e) => s + e.amount);

  List<(String, int)> byCategory(Iterable<Entry> es) {
    final totals = <String, int>{};
    for (final e in es) {
      totals[e.categoryKey] = (totals[e.categoryKey] ?? 0) + e.amount;
    }
    return totals.entries.map((e) => (e.key, e.value)).toList()..sort((a, b) => b.$2.compareTo(a.$2));
  }

  final days = [for (var d = from; !d.isAfter(to); d = DateTime.utc(d.year, d.month, d.day + 1)) d];
  int spentOn(DateTime d) => d.isBefore(first) ? 0 : wantsSpent(entries, fixed, d, d);
  // Today is still under way, so it counts toward no habit yet; a past
  // period is finished throughout.
  final finished = days.where((d) => d != now).toList();

  var weeksUnder = 0, fullWeeks = 0;
  for (var monday = weekStart(from); !monday.isAfter(to); monday = DateTime.utc(monday.year, monday.month, monday.day + 7)) {
    final sunday = DateTime.utc(monday.year, monday.month, monday.day + 6);
    if (monday.isBefore(from) || sunday.isAfter(to) || !sunday.isBefore(now)) continue;
    fullWeeks++;
    if (wantsSpent(entries, fixed, monday, sunday) <= weeklyCap) weeksUnder++;
  }

  final byLabel = <String, List<int>>{};
  for (final e in flexible.where((e) => e.label != null)) {
    byLabel.putIfAbsent(e.label!, () => []).add(e.amount);
  }
  final top = byLabel.entries.where((e) => e.value.length > 1).fold<MapEntry<String, List<int>>?>(
        null,
        (best, e) => best == null || e.value.length > best.value.length ? e : best,
      );

  // Planned money: bills, goals, and anything spent on a planned event.
  OutPart partOf(Entry e) => e.categoryKey == untrackedCategoryKey
      ? OutPart.untracked
      : !e.isFlexible(fixed)
          ? OutPart.planned
          : e.spendKind == SpendKind.want
              ? OutPart.wants
              : OutPart.needs;
  // Newest day first; within a day, the one logged last.
  final newestFirst = [...out]..sort((a, b) => b.day != a.day ? b.day.compareTo(a.day) : b.id.compareTo(a.id));

  return Insights(
    period: period,
    from: from,
    to: to,
    moneyIn: sum(inPeriod.where((e) => e.isIncome)),
    moneyOut: sum(out),
    outParts: {
      for (final part in OutPart.values) part: [for (final e in newestFirst) if (partOf(e) == part) e],
    },
    wantsByCategory: byCategory(wants),
    outByCategory: byCategory(out),
    outEntries: newestFirst,
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
    biggest: wants.isEmpty ? null : wants.reduce((a, b) => b.amount > a.amount ? b : a),
  );
}
