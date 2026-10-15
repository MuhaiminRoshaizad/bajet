import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/dates/dates.dart';
import '../../../core/money/money.dart';
import '../../../core/navigation/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/validation/ringgit_cents_formatter.dart';
import '../../../core/widgets/money_field.dart';
import '../../ledger/presentation/ledger_providers.dart';
import '../../plan/domain/plan_repository.dart';
import '../../plan/presentation/plan_providers.dart';

/// Changing the balance means one of two things: the bank disagrees today,
/// or setup was given the wrong figure. The first is a logged difference,
/// which the check-in already records; the second rewrites the opening
/// balance, so everything since moves with it.
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

  Future<void> _saveOpening(PlanSettings s) async {
    if (!_form.currentState!.validate()) return;
    await ref.read(planRepositoryProvider).saveSettings(PlanSettings(
          openingBalance: RinggitCentsFormatter.parse(_opening.text),
          openingDate: s.openingDate,
          weeklyCap: s.weeklyCap,
          buffer: s.buffer,
        ));
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final balance = ref.watch(balanceProvider).value;
    final settings = ref.watch(settingsProvider).value;
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
                onPressed: settings == null
                    ? null
                    : () => setState(() {
                          _fixing = true;
                          _opening.text = RinggitCentsFormatter.format(settings.openingBalance);
                        }),
                style: TextButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                child: const Text('Fix the starting balance instead'),
              ),
            ] else if (settings != null) ...[
              Text(
                'For a wrong figure at setup. Every balance since ${Dates.full(settings.openingDate)} moves by the difference; nothing is logged.',
                style: TextStyle(color: c.muted, height: 1.4),
              ),
              const SizedBox(height: AppSpacing.l),
              MoneyField(
                controller: _opening,
                label: 'Balance on ${Dates.full(settings.openingDate)}',
                hint: 'e.g. 2,500.00',
                textInputAction: TextInputAction.done,
                validator: (sen) => sen > 0 ? null : 'Enter the starting balance',
              ),
              const SizedBox(height: AppSpacing.xl),
              FilledButton(
                onPressed: () => _saveOpening(settings),
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
