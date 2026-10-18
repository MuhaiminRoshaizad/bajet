import '../../../core/dates/dates.dart';
import '../../../core/money/money.dart';
import '../../accounts/domain/account_models.dart';
import '../../insights/domain/insights.dart';
import '../../ledger/domain/ledger_models.dart';
import '../../plan/domain/projection.dart';

/// Entries in the period of [i], oldest first.
List<Entry> entriesIn(Insights i, List<Entry> entries) =>
    [...entries.where((e) => !e.day.isBefore(i.from) && !e.day.isAfter(i.to))]..sort((a, b) => a.day.compareTo(b.day) != 0 ? a.day.compareTo(b.day) : a.id.compareTo(b.id));

/// One account over a report's period: money logged in and out of it, and
/// what it holds now. Moves between the user's own accounts are neither.
class AccountLine {
  const AccountLine(this.id, this.name, this.moneyIn, this.moneyOut, this.balance);

  final int id;
  final String name;
  final int moneyIn;
  final int moneyOut;
  final int balance;
}

/// Each of [accounts], in their own order, over [entries] (those in the
/// period). An entry with no account belongs to the first.
List<AccountLine> byAccount(List<Account> accounts, List<Entry> entries) => [
      for (final a in accounts)
        () {
          final own = entries.where((e) => (e.accountId ?? accounts.first.id) == a.id);
          int sum(Iterable<Entry> es) => es.fold(0, (s, e) => s + e.amount);
          return AccountLine(a.id, a.called, sum(own.where((e) => e.isIncome)), sum(own.where((e) => !e.isIncome)), a.balance);
        }(),
    ];

/// The name of the account [e] was logged to, the first one if it has none.
String accountOf(List<AccountLine> accounts, Entry e) =>
    accounts.where((a) => a.id == (e.accountId ?? accounts.first.id)).firstOrNull?.name ?? accounts.first.name;

/// A plain-text report of [i], to paste into a chat or a note. [accounts]
/// break it down by account once there is more than one. Lines with
/// nothing to say, such as a total of RM0.00, are left out.
String reportText({
  required Insights i,
  required List<AccountLine> accounts,
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
    'Balance today: ${Money.format(balance)}',
    if (i.moneyIn > 0) 'Money in: ${Money.format(i.moneyIn)}',
    if (i.moneyOut > 0) 'Money out: ${Money.format(i.moneyOut)}',
    // A week rarely holds a payday, so in against out says little about it.
    if (i.period != InsightsPeriod.week && !i.isEmpty)
      i.kept >= 0
          ? 'Kept: ${Money.format(i.kept)}${share == null ? '' : ' ($share% of what came in)'}'
          : 'Spent more than came in: ${Money.format(-i.kept)}',
    if (accounts.length > 1) ...[
      '',
      'By account:',
      for (final a in accounts)
        '- ${a.name}: ${[
          if (a.moneyIn > 0) 'in ${Money.format(a.moneyIn)}',
          if (a.moneyOut > 0) 'out ${Money.format(a.moneyOut)}',
          if (a.moneyIn == 0 && a.moneyOut == 0) 'nothing in or out',
          'now ${Money.format(a.balance)}',
        ].join(', ')}',
    ],
    if (i.moneyOut > 0) ...[
      '',
      'Money out by kind:',
      if (i.fixedOut > 0) '- Fixed: ${Money.format(i.fixedOut)}',
      if (i.flexibleOut > 0) '- Flexible: ${Money.format(i.flexibleOut)}',
      if (i.untrackedOut > 0) '- Untracked: ${Money.format(i.untrackedOut)}',
      '',
      'Money out by category:',
      for (final (key, amount) in i.outByCategory) '- ${categoryName(categories, key)}: ${Money.format(amount)}',
    ],
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

/// A category's label, marked when it is fixed spending such as a bill.
String categoryName(Map<String, Category> categories, String key) {
  final c = categories[key];
  return c == null ? key : (c.isFixed ? '${c.label} (fixed)' : c.label);
}

/// Every entry in [entries] as CSV for a spreadsheet: one header row, ISO
/// dates so spreadsheets sort them, and plain amounts with the direction in
/// its own column. Fields are quoted per RFC 4180 where needed.
String reportCsv(List<Entry> entries, Map<String, Category> categories, List<AccountLine> accounts) {
  String field(String v) => RegExp(r'[",\r\n]').hasMatch(v) ? '"${v.replaceAll('"', '""')}"' : v;
  String day(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  final rows = [
    'date,type,account,category,label,note,amount',
    for (final e in entries)
      [
        day(e.day),
        e.isIncome ? 'income' : 'expense',
        field(accountOf(accounts, e)),
        field(categories[e.categoryKey]?.label ?? e.categoryKey),
        field(e.label ?? ''),
        field(e.note ?? ''),
        (e.amount / 100).toStringAsFixed(2),
      ].join(','),
  ];
  // RFC 4180 separates records with CRLF.
  return '${rows.join('\r\n')}\r\n';
}
