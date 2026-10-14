import '../../../core/dates/dates.dart';
import '../../../core/money/money.dart';
import '../../insights/domain/insights.dart';
import '../../ledger/domain/ledger_models.dart';
import '../../plan/domain/projection.dart';

/// Entries in the period of [i], oldest first.
List<Entry> entriesIn(Insights i, List<Entry> entries) =>
    [...entries.where((e) => !e.day.isBefore(i.from) && !e.day.isAfter(i.to))]..sort((a, b) => a.day.compareTo(b.day) != 0 ? a.day.compareTo(b.day) : a.id.compareTo(b.id));

/// A plain-text report of [i], to paste into a chat or a note.
String reportText({
  required Insights i,
  required int balance,
  required int weeklyCap,
  required int buffer,
  required Map<String, Category> categories,
  required GoalOutcome? goal,
}) {
  final share = i.moneyIn == 0 ? null : (i.kept / i.moneyIn * 100).round();
  final lines = [
    'bajet report, ${Dates.full(i.from)} to ${Dates.full(i.to)}',
    '',
    'Balance: ${Money.format(balance)}',
    'Money in: ${Money.format(i.moneyIn)}',
    'Money out: ${Money.format(i.moneyOut)}',
    i.kept >= 0
        ? 'Kept: ${Money.format(i.kept)}${share == null ? '' : ' ($share% of what came in)'}'
        : 'Spent more than came in: ${Money.format(-i.kept)}',
    '',
    'Money out by kind:',
    '- Fixed: ${Money.format(i.fixedOut)}',
    '- Flexible: ${Money.format(i.flexibleOut)}',
    if (i.untrackedOut > 0) '- Untracked: ${Money.format(i.untrackedOut)}',
    '',
    'Flexible spending by category:',
    if (i.flexibleByCategory.isEmpty) '- None',
    for (final (key, amount) in i.flexibleByCategory) '- ${categories[key]?.label ?? key}: ${Money.format(amount)}',
    '',
    'Habits:',
    if (i.daysSoFar > 0) '- ${i.daysWithinPlan} of ${i.daysSoFar} days within plan',
    if (i.daysSoFar > 0) '- ${i.zeroSpendDays} no-spend days',
    if (i.fullWeeks > 0) '- ${i.weeksUnderAllowance} of ${i.fullWeeks} weeks under the ${Money.format(weeklyCap)} allowance',
    if (i.frequent != null) '- Usual ${i.frequent!.label.toLowerCase()}: ${Money.format(i.frequent!.average)} (${i.frequent!.count} times)',
    if (i.biggest != null) '- Biggest extra: ${Money.format(i.biggest!.amount)} on ${Dates.full(i.biggest!.day)}',
    if (goal != null) ...[
      '',
      'Goal: ${goal.goal.name}, ${Money.format(goal.goal.price)} on ${Dates.full(goal.goal.targetDate)}',
      'Projected left after buying: ${Money.format(goal.leftAfterBuying)} '
          '(${goal.onTrack ? 'on track' : 'short'} against a ${Money.format(buffer)} buffer)',
    ],
  ];
  return lines.join('\n');
}

/// Every entry in [entries] as CSV for a spreadsheet: one header row, ISO
/// dates so spreadsheets sort them, and plain amounts with the direction in
/// its own column. Fields are quoted per RFC 4180 where needed.
String reportCsv(List<Entry> entries, Map<String, Category> categories) {
  String field(String v) => RegExp(r'[",\r\n]').hasMatch(v) ? '"${v.replaceAll('"', '""')}"' : v;
  String day(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  final rows = [
    'date,type,category,label,note,amount',
    for (final e in entries)
      [
        day(e.day),
        e.isIncome ? 'income' : 'expense',
        field(categories[e.categoryKey]?.label ?? e.categoryKey),
        field(e.label ?? ''),
        field(e.note ?? ''),
        (e.amount / 100).toStringAsFixed(2),
      ].join(','),
  ];
  // RFC 4180 separates records with CRLF.
  return '${rows.join('\r\n')}\r\n';
}
