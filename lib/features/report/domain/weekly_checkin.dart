import '../../../core/dates/dates.dart';
import '../../../core/money/money.dart';
import '../../checkin/domain/checkin.dart';
import '../../insights/domain/insights.dart';
import '../../ledger/domain/ledger_models.dart';
import '../../plan/domain/plan_models.dart';
import '../../plan/domain/projection.dart';
import '../../plan/domain/upcoming.dart';
import 'report.dart';

/// Where a day of the check-in's week stands.
enum CheckinDayState {
  /// Before the first day bajet knows about.
  noData,
  finished,

  /// Still under way, so it counts toward nothing yet.
  today,

  /// Later in the week than the check-in.
  ahead,
}

/// One day of the week: its flexible spending against its plan, and the
/// rhythm rule it follows.
class CheckinDay {
  const CheckinDay(this.date, this.spent, this.rule, this.state);

  final DateTime date;
  final int spent;
  final WeeklyRule rule;
  final CheckinDayState state;

  int get planned => rule.plannedSpend;
  bool get over => state == CheckinDayState.finished && spent > planned;
}

/// A rule of the rhythm on a finished day, such as a no-spending day, and
/// whether it held.
class RuleCheck {
  const RuleCheck(this.name, this.how, this.kept);

  /// The rhythm's own label and the weekday, such as `Rest (Sun)`.
  final String name;

  /// What keeping it means, such as `nothing spent`.
  final String how;
  final bool kept;
}

/// Flexible spending in one category over the week.
class CategorySpend {
  const CategorySpend(this.key, this.label, this.amount);

  final String key;
  final String label;
  final int amount;
}

/// The week is judged against the target saved at the last check-in, when
/// one was saved for today; otherwise this check-in only sets the baseline.
enum WeekVerdict { onTrack, short, baseline }

/// Everything the weekly check-in report says, worked out once for its
/// text, PDF and share card. Amounts are sen.
class WeeklyCheckin {
  const WeeklyCheckin({
    required this.today,
    required this.from,
    required this.first,
    required this.balance,
    required this.target,
    required this.matched,
    required this.untracked,
    required this.startingAdjustment,
    required this.spent,
    required this.plan,
    required this.categories,
    required this.days,
    required this.rules,
    required this.goal,
    required this.change,
    required this.withUnconfirmed,
    required this.buffer,
    required this.next,
    required this.nextTarget,
    required this.entries,
  });

  final DateTime today;

  /// The first day the week's figures cover: Monday, or a later first day.
  final DateTime from;

  /// No check-in was finished before this one.
  final bool first;
  final int balance;

  /// The balance the last check-in expected today; null when none did.
  final int? target;

  /// Whether every account matched at today's saved check-in; null until
  /// one is saved.
  final bool? matched;
  final int untracked;
  final int startingAdjustment;

  /// Flexible spending from [from] to today, today included.
  final int spent;

  /// The weekly allowance, or for a week that started late what the rhythm
  /// plans from [from] to Sunday.
  final int plan;

  /// Flexible spending by category, largest first.
  final List<CategorySpend> categories;

  /// Monday to Sunday.
  final List<CheckinDay> days;
  final List<RuleCheck> rules;
  final GoalOutcome? goal;

  /// How much more the goal leaves after buying than at the last check-in.
  final int? change;

  /// What the goal leaves if unconfirmed income arrives too; null when that
  /// changes nothing.
  final int? withUnconfirmed;
  final int buffer;

  /// What is planned over the next seven days, soonest first.
  final List<UpcomingItem> next;

  /// What the plan expects at the next check-in, a week on.
  final int nextTarget;

  /// The week's entries, oldest first.
  final List<Entry> entries;

  DateTime get monday => weekStart(today);
  DateTime get sunday => DateTime.utc(monday.year, monday.month, monday.day + 6);
  DateTime get nextCheck => DateTime.utc(today.year, today.month, today.day + 7);

  /// Days of data so far, today included.
  int get dataDays => today.difference(from).inDays + 1;

  WeekVerdict get verdict => switch (target) {
        null => WeekVerdict.baseline,
        final t => balance >= t ? WeekVerdict.onTrack : WeekVerdict.short,
      };
  int? get difference => target == null ? null : balance - target!;
  bool? get goalSafe => goal == null ? null : goal!.leftAfterBuying >= buffer;
  int? get daysToGo => goal == null ? null : calendarDay(goal!.goal.targetDate).difference(today).inDays;

  List<CheckinDay> get finished => [...days.where((d) => d.state == CheckinDayState.finished)];
  int get withinPlan => finished.where((d) => !d.over).length;
  int get noSpendDays => finished.where((d) => d.spent == 0).length;
  List<CheckinDay> get overDays => [...finished.where((d) => d.over)];

  /// What needs a look; empty when nothing does.
  List<String> get flags => [
        if (untracked > 0) '${Money.format(untracked)} untracked, found at this check-in',
        if (matched == false) 'Not every account matched',
        if (overDays.isNotEmpty) '${_and([for (final d in overDays) Dates.weekday(d.date)])} went over ${overDays.length == 1 ? 'its' : 'their'} plan',
        if (goalSafe == false) '${goal!.goal.name} leaves ${Money.format(goal!.leftAfterBuying)} after buying, under the ${Money.format(buffer)} buffer',
      ];
}

String _and(List<String> items) => items.length < 2 ? items.join() : '${items.sublist(0, items.length - 1).join(', ')} and ${items.last}';

/// The check-in of [today]'s week. [projection] runs at least a week on;
/// [unconfirmed] is the same with unconfirmed income counted. [checkins]
/// are every finished check-in, newest first.
WeeklyCheckin weeklyCheckin({
  required DateTime today,
  required DateTime openingDate,
  required int weeklyCap,
  required int buffer,
  required int balance,
  required List<Entry> entries,
  required List<Category> categories,
  required List<WeeklyRule> rules,
  required List<Checkin> checkins,
  required Projection projection,
  required Projection unconfirmed,
  required List<RecurringItem> recurring,
  required List<PlannedEvent> events,
  required List<Goal> goals,
}) {
  final week = insights(
    period: InsightsPeriod.week,
    today: today,
    openingDate: openingDate,
    weeklyCap: weeklyCap,
    entries: entries,
    categories: categories,
    rules: rules,
  );
  final fixed = {for (final c in categories.where((c) => c.isFixed)) c.key};
  final labels = {for (final c in categories) c.key: c.label};
  final monday = weekStart(today);
  final saved = checkins.where((c) => c.checkedOn == today).firstOrNull;
  final previous = checkins.where((c) => c.checkedOn.isBefore(today)).firstOrNull;
  final first = previous == null;

  final days = [
    for (var n = 0; n < 7; n++)
      () {
        final d = DateTime.utc(monday.year, monday.month, monday.day + n);
        final state = d.isBefore(week.from)
            ? CheckinDayState.noData
            : d == today
                ? CheckinDayState.today
                : d.isAfter(today)
                    ? CheckinDayState.ahead
                    : CheckinDayState.finished;
        final rule = rules.firstWhere((r) => r.weekday == d.weekday);
        return CheckinDay(d, state == CheckinDayState.noData ? 0 : flexibleSpent(entries, fixed, d, d), rule, state);
      }(),
  ];

  bool ateOn(DateTime d) => entries.any((e) => e.day == d && !e.isIncome && e.categoryKey == foodCategoryKey);
  String name(CheckinDay d) => '${d.rule.label} (${Dates.weekday(d.date)})';
  final ruleChecks = [
    for (final d in days.where((d) => d.state == CheckinDayState.finished)) ...[
      if (d.rule.isFastingDay) RuleCheck(name(d), 'no Food spending', !ateOn(d.date)),
      if (d.rule.type == DayType.zero) RuleCheck(name(d), 'nothing spent', d.spent == 0),
      if (d.rule.type == DayType.flex) RuleCheck(name(d), 'within ${Money.format(d.planned)}', !d.over),
    ],
  ];

  // Money found untracked this week. At the first check-in it comes from an
  // opening balance slightly off, not from missed logging (decision 027).
  final found = week.untrackedOut;
  final goal = projection.goals.firstOrNull;
  final withUnconfirmed = unconfirmed.goals.firstOrNull?.leftAfterBuying;
  final nextCheck = DateTime.utc(today.year, today.month, today.day + 7);
  final lastLeft = previous?.leftAfterBuying;
  return WeeklyCheckin(
    today: today,
    from: week.from,
    first: first,
    balance: balance,
    target: previous != null && previous.targetOn == today ? previous.nextTarget : null,
    matched: saved?.matched,
    untracked: saved?.untracked ?? (first ? 0 : found),
    startingAdjustment: saved?.startingAdjustment ?? (first ? found : 0),
    spent: week.flexibleOut,
    // A whole week is held to the allowance; a first, shorter one to what
    // the rhythm plans for the days it covers.
    plan: week.from == monday ? weeklyCap : days.where((d) => d.state != CheckinDayState.noData).fold(0, (sum, d) => sum + d.planned),
    categories: [for (final (key, amount) in week.flexibleByCategory) CategorySpend(key, labels[key] ?? key, amount)],
    days: days,
    rules: ruleChecks,
    goal: goal,
    change: goal == null || lastLeft == null ? null : goal.leftAfterBuying - lastLeft,
    withUnconfirmed: withUnconfirmed == goal?.leftAfterBuying ? null : withUnconfirmed,
    buffer: buffer,
    next: upcoming(
      recurring: recurring,
      events: events,
      goals: goals,
      from: DateTime.utc(today.year, today.month, today.day + 1),
      to: nextCheck,
    ),
    nextTarget: saved?.nextTarget ?? projection.days.firstWhere((d) => d.date == nextCheck).balance,
    entries: entriesIn(week, entries),
  );
}

/// `+RM8.50` or `−RM4.20`.
String signedMoney(int sen) => '${sen < 0 ? '−' : '+'}${Money.format(sen.abs())}';

/// The check-in as plain text to paste into a chat, verdict first. Lines
/// with nothing to say are left out.
String weeklyCheckinText(WeeklyCheckin w) {
  final goal = w.goal;
  final safe = w.goalSafe;
  final goalState = safe == null ? '' : ' · goal ${w.verdict == WeekVerdict.short && safe ? 'still ' : ''}${safe ? 'SAFE' : 'SHORT'}';
  final under = w.plan - w.spent;
  final lines = [
    'bajet · weekly check-in · ${Dates.dayShort(w.monday)} – ${Dates.dayFull(w.sunday)}',
    if (w.dataDays < 7) '${w.first ? 'First check-in · ' : ''}${w.dataDays} ${w.dataDays == 1 ? 'day' : 'days'} of data (${Dates.short(w.from)}–${Dates.short(w.today)})',
    '',
    switch (w.verdict) {
      WeekVerdict.onTrack => 'CHECK-IN: ON TRACK ✓$goalState',
      WeekVerdict.short => 'CHECK-IN: SHORT ${Money.format(-w.difference!)} this week$goalState',
      WeekVerdict.baseline => 'CHECK-IN: BASELINE SET$goalState${goal == null ? '' : ' (${Money.format(goal.leftAfterBuying)} left after buying)'}',
    },
    switch (w.target) {
      null => 'Balance ${Money.format(w.balance)} · target for ${Dates.dayShort(w.nextCheck)} set at this check-in',
      final t => 'Balance ${Money.format(w.balance)} vs target ${Money.format(t)} (${signedMoney(w.difference!)})',
    },
    [
      'Bank match: ${switch (w.matched) { true => 'yes', false => 'no', null => 'not checked yet' }}',
      if (w.startingAdjustment > 0) 'starting adjustment ${Money.format(w.startingAdjustment)} (not counted as untracked)' else 'untracked ${Money.format(w.untracked)}',
    ].join(' · '),
    '',
    'THIS WEEK',
    'Spent ${Money.format(w.spent)} of ${Money.format(w.plan)}${w.from == w.monday ? '' : ' planned for these days'} '
        '(${Money.format(under.abs())} ${under >= 0 ? 'under' : 'over'})',
    if (w.categories.isNotEmpty) '  ${w.categories.map((c) => '${c.label} ${Money.format(c.amount)}').join(' · ')}',
    if (w.finished.isNotEmpty) 'Days: ${w.withinPlan} of ${w.finished.length} finished days within plan · ${w.noSpendDays} no-spend ${w.noSpendDays == 1 ? 'day' : 'days'}',
    if (w.days.any((d) => d.state == CheckinDayState.today)) '  Today counts once it is over',
    if (w.rules.isNotEmpty) 'Rules: ${w.rules.map((r) => '${r.name} ${r.kept ? 'kept' : 'missed'}').join(' · ')}',
    if (goal != null) ...[
      '',
      'GOAL · ${goal.goal.name} · ${Money.format(goal.goal.price)} · ${Dates.dayFull(goal.goal.targetDate)} (${w.daysToGo} ${w.daysToGo == 1 ? 'day' : 'days'})',
      'Left after buying: ${Money.format(goal.leftAfterBuying)}${w.change == null ? '' : ' (${signedMoney(w.change!)} since last check-in)'}',
      if (w.withUnconfirmed != null) 'With unconfirmed income: ${Money.format(w.withUnconfirmed!)}',
      if (w.buffer > 0) 'Buffer ${Money.format(w.buffer)}: ${safe! ? 'SAFE' : 'SHORT'}',
    ],
    '',
    'NEXT 7 DAYS',
    if (w.next.isEmpty) 'Nothing due',
    for (final item in w.next)
      '${Dates.dayShort(item.date).padRight(12)}${item.name.padRight(20)} ${signedMoney(item.signedAmount)}${item.counted ? '' : ' (unconfirmed)'}',
    'Next check-in: ${Dates.dayShort(w.nextCheck)}, stay above ${Money.format(w.nextTarget)}',
    if (w.flags.isNotEmpty) ...['', 'FLAGS', for (final f in w.flags) '- $f'],
  ];
  return lines.join('\n');
}
