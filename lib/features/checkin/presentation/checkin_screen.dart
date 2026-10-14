import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../../core/dates/dates.dart';
import '../../../core/money/money.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/validation/ringgit_cents_formatter.dart';
import '../../../core/widgets/money_field.dart';
import '../../../core/widgets/soft.dart';
import '../../ledger/domain/ledger_models.dart';
import '../../ledger/presentation/ledger_providers.dart';
import '../../ledger/presentation/log_sheet.dart';
import '../../plan/presentation/plan_providers.dart';
import '../../today/presentation/today_providers.dart';
import '../../today/presentation/weekly_ring.dart';

/// The weekly look back: does bajet's balance match the bank, and how did
/// the week go against the rhythm. Any gap can be logged on the spot.
class CheckinScreen extends ConsumerStatefulWidget {
  const CheckinScreen({super.key});

  @override
  ConsumerState<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends ConsumerState<CheckinScreen> {
  final _bank = TextEditingController();

  @override
  void initState() {
    super.initState();
    _bank.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _bank.dispose();
    super.dispose();
  }

  Future<void> _logMissing(int amount) async {
    final repo = ref.read(ledgerRepositoryProvider);
    final id = await repo.add(EntryDraft(
      day: ref.read(todayProvider),
      isIncome: false,
      amount: amount,
      categoryKey: untrackedCategoryKey,
      label: 'Untracked',
      note: 'Found at check-in',
    ));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text('Logged ${Money.format(amount)} as untracked'),
        action: SnackBarAction(label: 'Undo', onPressed: () => repo.delete(id)),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final today = ref.watch(todayProvider);
    final monday = weekStart(today);
    final balance = ref.watch(balanceProvider).value;
    final days = ref.watch(weekDaysProvider);
    final spent = ref.watch(weekSpentProvider);
    final cap = ref.watch(settingsProvider).value?.weeklyCap;
    final bank = _bank.text.isEmpty ? null : RinggitCentsFormatter.parse(_bank.text);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Sunday check-in')),
        body: ListView(
          padding: const EdgeInsets.all(AppSpacing.l),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xs, 0, AppSpacing.xs, AppSpacing.m),
              child: Text(
                'Week of ${Dates.short(monday)} to ${Dates.short(DateTime.utc(monday.year, monday.month, monday.day + 6))}',
                style: TextStyle(color: c.muted),
              ),
            ),
            SoftCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Does it match your bank?', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: AppSpacing.m),
                  Row(
                    children: [
                      Text('bajet says', style: TextStyle(color: c.muted)),
                      const SizedBox(width: AppSpacing.s),
                      Expanded(
                        child: Text(
                          balance == null ? '—' : Money.format(balance),
                          textAlign: TextAlign.end,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontFeatures: [FontFeature.tabularFigures()]),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.m),
                  MoneyField(
                    controller: _bank,
                    label: 'Bank app says',
                    hint: 'e.g. 2,412.60',
                    helper: 'Add up your accounts as your bank app shows them right now.',
                    textInputAction: TextInputAction.done,
                  ),
                  if (bank != null && balance != null) ...[
                    const SizedBox(height: AppSpacing.m),
                    _Gap(difference: balance - bank, onLogMissing: _logMissing),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.l),
            if (days != null && spent != null && cap != null) SoftCard(child: _Week(days: days, spent: spent, cap: cap)),
          ],
        ),
      ),
    );
  }
}

/// What to do about a difference between bajet and the bank. Positive means
/// bajet thinks there is more than the bank holds.
class _Gap extends StatelessWidget {
  const _Gap({required this.difference, required this.onLogMissing});

  final int difference;
  final ValueChanged<int> onLogMissing;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    if (difference == 0) return _Pill(text: 'Matches exactly', good: true);
    final missing = difference > 0;
    final amount = difference.abs();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Pill(text: missing ? '${Money.format(amount)} spent but not logged' : '${Money.format(amount)} more in the bank', good: false),
        const SizedBox(height: AppSpacing.s),
        Text(
          missing
              ? 'If you cannot remember what it was, log it as untracked so the balance is right again.'
              : 'Money came in that bajet does not know about. Log it as income.',
          style: TextStyle(color: c.muted, height: 1.4),
        ),
        const SizedBox(height: AppSpacing.s),
        FilledButton.tonal(
          onPressed: missing ? () => onLogMissing(amount) : () => showLogSheet(context, prefill: LogPrefill(isIncome: true, amount: amount)),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          child: Text(missing ? 'Log ${Money.format(amount)} as untracked' : 'Log the income'),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.good});

  final String text;
  final bool good;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.xs + 1),
        decoration: BoxDecoration(color: good ? c.goodSurface : c.badSurface, borderRadius: BorderRadius.circular(AppRadii.pill)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(good ? Icons.check_rounded : Icons.priority_high_rounded, size: 16, color: good ? c.good : c.bad),
            const SizedBox(width: AppSpacing.xs),
            Flexible(child: Text(text, style: TextStyle(color: good ? c.good : c.bad, fontWeight: FontWeight.w600))),
          ],
        ),
      ),
    );
  }
}

/// The week day by day against the rhythm, and the allowance as a whole.
class _Week extends StatelessWidget {
  const _Week({required this.days, required this.spent, required this.cap});

  final List<WeekDay> days;
  final int spent;
  final int cap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final past = days.where((d) => d.status != DayStatus.ahead && d.status != DayStatus.today);
    final kept = past.where((d) => d.status == DayStatus.kept).length;
    final left = cap - spent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Text('This week', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(width: AppSpacing.s),
            Expanded(
              child: Text(
                '${Money.format(spent)} of ${Money.formatWhole(cap)}',
                textAlign: TextAlign.end,
                style: TextStyle(color: c.muted, fontFeatures: const [FontFeature.tabularFigures()]),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.m),
        Row(
          children: [
            for (final (i, d) in days.indexed) ...[
              if (i > 0) const SizedBox(width: AppSpacing.xs + 2),
              Expanded(child: _DayCell(day: d)),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.m),
        if (past.isNotEmpty) Text('$kept of ${past.length} ${past.length == 1 ? 'day' : 'days'} so far within plan'),
        Text(
          left >= 0 ? '${Money.format(left)} of the allowance left' : '${Money.format(-left)} over the allowance',
          style: TextStyle(color: left >= 0 ? c.good : c.bad, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({required this.day});

  final WeekDay day;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (bg, fg) = switch (day.status) {
      DayStatus.kept => (c.goodSurface, c.good),
      DayStatus.over => (c.badSurface, c.bad),
      DayStatus.today => (c.primarySoft, c.ink),
      DayStatus.ahead => (c.well, c.muted),
    };
    final status = switch (day.status) {
      DayStatus.kept => 'within plan',
      DayStatus.over => 'over plan',
      DayStatus.today => 'today',
      DayStatus.ahead => 'to come',
    };
    return Semantics(
      label: '${day.label}, ${Money.format(day.spent)}, $status',
      excludeSemantics: true,
      child: Column(
        children: [
          Container(
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppRadii.small)),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Text(
                  day.status == DayStatus.ahead ? '' : Money.formatWhole(day.spent).replaceFirst('RM', ''),
                  style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(day.label.substring(0, 1), style: TextStyle(color: c.muted, fontSize: 12)),
        ],
      ),
    );
  }
}
