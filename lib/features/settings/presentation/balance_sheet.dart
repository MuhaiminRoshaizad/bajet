import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/dates/dates.dart';
import '../../../core/money/money.dart';
import '../../../core/navigation/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/validation/ringgit_cents_formatter.dart';
import '../../../core/widgets/done_bar.dart';
import '../../../core/widgets/money_field.dart';
import '../../accounts/domain/account_models.dart';
import '../../accounts/presentation/account_choice.dart';
import '../../accounts/presentation/account_providers.dart';
import '../../ledger/presentation/ledger_providers.dart';
import '../../plan/presentation/plan_providers.dart';

/// Changing the balance means one of two things: an account disagrees
/// today, or it was given the wrong starting figure. The first is a logged
/// difference, which the check-in records; the second rewrites that
/// account's opening balance, so everything since moves with it.
Future<void> showBalanceSheet(BuildContext context) =>
    showModalBottomSheet<void>(context: context, isScrollControlled: true, useSafeArea: true, builder: (_) => const _BalanceSheet());

class _BalanceSheet extends ConsumerStatefulWidget {
  const _BalanceSheet();

  @override
  ConsumerState<_BalanceSheet> createState() => _BalanceSheetState();
}

class _BalanceSheetState extends ConsumerState<_BalanceSheet> {
  final _form = GlobalKey<FormState>();
  final _opening = TextEditingController();
  bool _fixing = false;

  /// The account whose starting balance is being fixed.
  Account? _account;

  @override
  void dispose() {
    _opening.dispose();
    super.dispose();
  }

  void _matchBank() {
    final router = GoRouter.of(context);
    Navigator.of(context).pop();
    router.push(Routes.checkin);
  }

  void _fix(Account account) => setState(() {
        _fixing = true;
        _account = account;
        _opening.text = RinggitCentsFormatter.format(account.openingBalance);
      });

  Future<void> _saveOpening() async {
    final account = _account;
    if (account == null || !_form.currentState!.validate()) return;
    final messenger = ScaffoldMessenger.of(context);
    final repo = ref.read(accountRepositoryProvider);
    final opening = RinggitCentsFormatter.parse(_opening.text);
    await repo.setOpeningBalance(account.id, opening);
    if (mounted) Navigator.of(context).pop();
    showBar(messenger, "Saved ${account.called}'s starting balance: ${Money.format(opening)}", undo: () => repo.setOpeningBalance(account.id, account.openingBalance));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final balance = ref.watch(balanceProvider).value;
    final settings = ref.watch(settingsProvider).value;
    final accounts = ref.watch(accountsProvider).value ?? const [];
    final title = Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700);
    return Padding(
      padding: EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl + MediaQuery.viewInsetsOf(context).bottom),
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(_fixing ? 'Fix the starting balance' : 'Your balance', style: title),
            const SizedBox(height: AppSpacing.s),
            if (!_fixing) ...[
              Text(
                balance == null ? '' : 'bajet has ${Money.format(balance)} from your entries.',
                style: TextStyle(color: c.muted, height: 1.4),
              ),
              const SizedBox(height: AppSpacing.l),
              FilledButton(
                onPressed: _matchBank,
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
                child: const Text('Match what you really have'),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.xs, AppSpacing.s, AppSpacing.xs, 0),
                child: Text(
                  'Type what your accounts hold now; the difference is logged today, so History shows why the balance changed.',
                  style: TextStyle(color: c.muted, fontSize: 13, height: 1.4),
                ),
              ),
              const SizedBox(height: AppSpacing.l),
              TextButton(
                onPressed: accounts.isEmpty ? null : () => _fix(accounts.first),
                style: TextButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                child: const Text('Fix the starting balance instead'),
              ),
            ] else if (settings != null && _account != null) ...[
              Text(
                'For a wrong figure when an account was set up. Its every balance since ${Dates.full(settings.openingDate)} moves by the difference; nothing is logged.',
                style: TextStyle(color: c.muted, height: 1.4),
              ),
              if (accounts.length > 1) ...[
                const SizedBox(height: AppSpacing.l),
                AccountChoice(
                  label: 'Which account?',
                  accounts: accounts,
                  selected: _account!.id,
                  onSelect: (id) => _fix(accounts.firstWhere((a) => a.id == id)),
                ),
              ],
              const SizedBox(height: AppSpacing.l),
              MoneyField(
                // A new field for each account, so its own figure shows.
                key: ValueKey(_account!.id),
                controller: _opening,
                label: '${accounts.length > 1 ? '${_account!.name} on' : 'Balance on'} ${Dates.full(settings.openingDate)}',
                hint: 'e.g. 2,500.00',
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: AppSpacing.xl),
              FilledButton(
                onPressed: _saveOpening,
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
                child: const Text('Save starting balance'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
