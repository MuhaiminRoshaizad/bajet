import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/money/money.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../accounts/domain/account_models.dart';
import '../../accounts/presentation/account_providers.dart';
import '../../accounts/presentation/card_face.dart';
import '../../ledger/presentation/ledger_providers.dart';
import '../../plan/domain/plan_models.dart';
import '../../plan/presentation/plan_providers.dart';

/// The front of Today's stack: the total, today's plan and how to see the
/// accounts. Also drawn by the opening, as the card it lands as.
class TodayTotalCard extends ConsumerWidget {
  const TodayTotalCard({super.key, this.countUp = false});

  /// Count up to the balance, as Today does when it opens.
  final bool countUp;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rule = ref.watch(todayRuleProvider);
    return TotalCard(
      look: ref.watch(totalCardLookProvider).value ?? const TotalCardLook(),
      balance: ref.watch(balanceProvider).value,
      accounts: ref.watch(accountsProvider).value ?? const [],
      countUp: countUp,
      hint: 'tap to see them',
      below: rule == null ? null : _PlanPill(rule: rule),
    );
  }
}

class _PlanPill extends StatelessWidget {
  const _PlanPill({required this.rule});

  final WeeklyRule rule;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.xs + 1),
      decoration: BoxDecoration(color: c.primarySoft, borderRadius: BorderRadius.circular(AppRadii.pill)),
      child: Text(
        rule.plannedSpend > 0 ? '${rule.label} · up to ${Money.format(rule.plannedSpend)}' : '${rule.label} · no spending planned',
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.primary),
      ),
    );
  }
}
