import '../../../core/dates/dates.dart';
import '../../../core/money/money.dart';
import '../../ledger/domain/ledger_models.dart';
import '../../plan/domain/plan_models.dart';
import '../../plan/domain/projection.dart';
import '../../plan/domain/upcoming.dart';

/// A short plain-text summary of the week, compact enough to paste into a
/// chat and ask for advice. Built only from data already on the phone.
String weekSummary({
  required DateTime today,
  required int balance,
  required int weeklyCap,
  required int buffer,
  required List<Entry> entries,
  required List<Category> categories,
  required List<WeeklyRule> rules,
  required Projection? projection,
  required List<UpcomingItem> upcoming,
}) {
  final monday = weekStart(today);
  final sunday = DateTime.utc(monday.year, monday.month, monday.day + 6);
  final byKey = {for (final c in categories) c.key: c};
  final fixed = {for (final c in categories.where((c) => c.isFixed)) c.key};
  final week = entries.where((e) => !e.day.isBefore(monday) && !e.day.isAfter(today)).toList();
  final spent = wantsSpent(week, fixed, monday, today);

  final perCategory = <String, int>{};
  for (final e in week.where((e) => !e.isIncome)) {
    perCategory[e.categoryKey] = (perCategory[e.categoryKey] ?? 0) + e.amount;
  }
  final categoryLines = (perCategory.entries.toList()..sort((a, b) => b.value.compareTo(a.value)))
      .map((e) => '- ${byKey[e.key]?.label ?? e.key}: ${Money.format(e.value)}${fixed.contains(e.key) ? ' (fixed)' : ''}');

  final overDays = <String>[];
  for (var d = monday; !d.isAfter(today); d = DateTime.utc(d.year, d.month, d.day + 1)) {
    final planned = rules.where((r) => r.weekday == d.weekday).firstOrNull?.plannedSpend ?? 0;
    final daySpent = wantsSpent(week, fixed, d, d);
    if (daySpent > planned) overDays.add('- ${Dates.weekday(d)} ${Dates.short(d)}: ${Money.format(daySpent)} against ${Money.format(planned)} planned');
  }

  final lines = [
    'bajet summary, week of ${Dates.full(monday)} to ${Dates.full(sunday)}',
    '',
    'Balance: ${Money.format(balance)}',
    'Flexible spending this week: ${Money.format(spent)} of ${Money.format(weeklyCap)} '
        '(${spent <= weeklyCap ? '${Money.format(weeklyCap - spent)} left' : '${Money.format(spent - weeklyCap)} over'})',
    '',
    'By category:',
    if (categoryLines.isEmpty) '- Nothing spent yet' else ...categoryLines,
    '',
    'Days over plan:',
    if (overDays.isEmpty) '- None' else ...overDays,
  ];

  final goal = projection?.goals.firstOrNull;
  if (goal != null) {
    lines.addAll([
      '',
      'Goal: ${goal.goal.name}, ${Money.format(goal.goal.price)} on ${Dates.full(goal.goal.targetDate)}',
      'Projected left after buying: ${Money.format(goal.leftAfterBuying)} '
          '(${goal.onTrack ? 'on track' : 'short'} against a ${Money.format(buffer)} buffer)',
    ]);
  }

  final next = upcoming.where((u) => !u.isGoal).take(3).toList();
  if (next.isNotEmpty) {
    lines.addAll([
      '',
      'Coming up:',
      for (final u in next)
        '- ${Dates.full(u.date)} ${u.name}: ${u.signedAmount > 0 ? '+' : '−'}${Money.format(u.signedAmount.abs())}${u.counted ? '' : ' (not counted)'}',
    ]);
  }
  return lines.join('\n');
}
