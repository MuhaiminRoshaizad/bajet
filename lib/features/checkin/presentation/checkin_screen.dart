import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/database_provider.dart';
import '../../../core/dates/dates.dart';
import '../../../core/money/money.dart';
import '../../../core/navigation/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/validation/ringgit_cents_formatter.dart';
import '../../../core/widgets/money_field.dart';
import '../../../core/widgets/soft.dart';
import '../../accounts/domain/account_models.dart';
import '../../accounts/presentation/account_providers.dart';
import '../../ledger/domain/ledger_models.dart';
import '../../ledger/presentation/ledger_providers.dart';
import '../../ledger/presentation/log_sheet.dart';
import '../../plan/presentation/plan_providers.dart';
import '../../today/presentation/today_providers.dart';
import '../../today/presentation/week_strip.dart';

/// The weekly look back: does bajet's balance match the bank, and how did
/// the week go against the rhythm. Any gap can be logged on the spot.
class CheckinScreen extends ConsumerStatefulWidget {
  const CheckinScreen({super.key});

  @override
  ConsumerState<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends ConsumerState<CheckinScreen> {
  /// What each account really holds, as typed, by account id.
  final _typed = <int, TextEditingController>{};

  TextEditingController _field(int accountId) => _typed.putIfAbsent(accountId, () => TextEditingController()..addListener(() => setState(() {})));

  @override
  void dispose() {
    for (final t in _typed.values) {
      t.dispose();
    }
    super.dispose();
  }

  Future<void> _logMissing(int amount, int accountId) async {
    final repo = ref.read(ledgerRepositoryProvider);
    final id = await repo.add(EntryDraft(
      day: ref.read(todayProvider),
      isIncome: false,
      amount: amount,
      categoryKey: untrackedCategoryKey,
      label: 'Untracked',
      note: 'Found at check-in',
      accountId: accountId,
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
    final accounts = ref.watch(accountsProvider).value ?? const [];
    final days = ref.watch(weekDaysProvider);
    final spent = ref.watch(weekSpentProvider);
    final cap = ref.watch(settingsProvider).value?.weeklyCap;
    // One account compares with the bank app as a whole; several each
    // compare with their own app or wallet.
    final single = accounts.length == 1;

    return Scaffold(
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
                Text(single ? 'Does it match your bank?' : 'Does each account match?', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                for (final a in accounts) ...[
                  const SizedBox(height: AppSpacing.l),
                  _AccountCheck(
                    account: a,
                    field: _field(a.id),
                    single: single,
                    onLogMissing: (amount) => _logMissing(amount, a.id),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.l),
          if (days != null && spent != null && cap != null) SoftCard(child: WeekStrip(days: days, spent: spent, cap: cap)),
          const SizedBox(height: AppSpacing.l),
          OutlinedButton.icon(
            onPressed: () => context.push('${Routes.report}?period=week'),
            icon: const Icon(Icons.ios_share_rounded),
            label: const Text("Share this week's report"),
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(56)),
          ),
        ],
      ),
    );
  }
}

/// One account: what bajet has, what it really holds, and the gap.
class _AccountCheck extends StatelessWidget {
  const _AccountCheck({required this.account, required this.field, required this.single, required this.onLogMissing});

  final Account account;
  final TextEditingController field;
  final bool single;
  final ValueChanged<int> onLogMissing;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final real = field.text.isEmpty ? null : RinggitCentsFormatter.parse(field.text);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      // The name gives way and the figure shrinks before either runs off.
      Row(children: [
        if (!single) ...[
          CircleAvatar(backgroundColor: Color(account.look.color), radius: 6),
          const SizedBox(width: AppSpacing.s),
        ],
        Expanded(
          child: Text(single ? 'bajet says' : account.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: single ? TextStyle(color: c.muted) : const TextStyle(fontWeight: FontWeight.w600)),
        ),
        const SizedBox(width: AppSpacing.s),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text.rich(TextSpan(children: [
              if (!single) TextSpan(text: 'bajet has ', style: TextStyle(color: c.muted)),
              TextSpan(text: Money.format(account.balance), style: const TextStyle(fontWeight: FontWeight.w700, fontFeatures: [FontFeature.tabularFigures()])),
            ])),
          ),
        ),
      ]),
      const SizedBox(height: AppSpacing.s),
      MoneyField(
        controller: field,
        label: single ? 'Bank app says' : account.kind == AccountKind.cash ? 'Counted in the wallet' : '${account.name} says',
        hint: 'e.g. 2,412.60',
        helper: single ? 'Add up your accounts as your bank app shows them right now.' : null,
        textInputAction: TextInputAction.done,
      ),
      if (real != null) ...[
        const SizedBox(height: AppSpacing.m),
        _Gap(difference: account.balance - real, accountId: account.id, onLogMissing: onLogMissing),
      ],
    ]);
  }
}

/// What to do about a difference between bajet and an account. Positive
/// means bajet thinks there is more than the account holds.
class _Gap extends StatelessWidget {
  const _Gap({required this.difference, required this.accountId, required this.onLogMissing});

  final int difference;
  final int accountId;
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
        _Pill(text: missing ? '${Money.format(amount)} spent but not logged' : '${Money.format(amount)} more than bajet has', good: false),
        const SizedBox(height: AppSpacing.s),
        Text(
          missing
              ? 'If you cannot remember what it was, log it as untracked so the balance is right again.'
              : 'Money came in that bajet does not know about. Log it as income.',
          style: TextStyle(color: c.muted, height: 1.4),
        ),
        const SizedBox(height: AppSpacing.s),
        FilledButton.tonal(
          onPressed: missing ? () => onLogMissing(amount) : () => showLogSheet(context, prefill: LogPrefill(isIncome: true, amount: amount, accountId: accountId)),
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
