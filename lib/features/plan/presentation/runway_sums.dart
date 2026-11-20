import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/money/money.dart';
import '../../../core/navigation/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/soft.dart';
import '../domain/projection.dart';

/// How "left after buying" is reached, line by line, so the figure is never
/// a black box. Without planned income it says so, since that alone can
/// turn a reachable goal into a shortfall. Money owed back by people the
/// user paid for is named but never counted, as late income is not.
class RunwaySumsCard extends StatelessWidget {
  const RunwaySumsCard({super.key, required this.outcome, this.owed = 0});

  final GoalOutcome outcome;

  /// Still owed back for spends partly for others.
  final int owed;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = outcome.sums;
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('How it adds up', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: AppSpacing.s),
          _Line('Balance today', s.balanceNow, sign: ''),
          _Line('Day-to-day spending until buy day', s.dailySpending, sign: '−'),
          if (s.needs > 0) _Line('Not my call until buy day', s.needs, sign: '−'),
          _Line('Income until buy day', s.income, sign: '+'),
          _Line('Bills and planned costs', s.costs, sign: '−'),
          if (s.earlierGoals > 0) _Line('Goals bought before it', s.earlierGoals, sign: '−'),
          _Line('${outcome.goal.name} price', outcome.goal.price, sign: '−'),
          Divider(color: c.line, height: AppSpacing.l),
          _Line('Left after buying', outcome.leftAfterBuying.abs(), sign: outcome.leftAfterBuying < 0 ? '−' : '', bold: true),
          if (owed > 0)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text('${Money.format(owed)} owed to you is not counted until it comes back.', style: TextStyle(color: c.muted, fontSize: 13)),
            ),
          if (s.income == 0) ...[
            const SizedBox(height: AppSpacing.m),
            SoftWell(
              radius: AppRadii.control,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'No income is planned before buy day, so none is counted. Add your salary or other pay as monthly income.',
                    style: TextStyle(color: c.ink, height: 1.4),
                  ),
                  const SizedBox(height: AppSpacing.s),
                  FilledButton.tonal(
                    onPressed: () => context.push(Routes.recurring),
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                    child: const Text('Add monthly income'),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.label, this.sen, {required this.sign, this.bold = false});

  final String label;
  final int sen;
  final String sign;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final weight = bold ? FontWeight.w700 : FontWeight.w500;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: TextStyle(color: bold ? context.colors.ink : context.colors.muted, fontWeight: weight))),
          const SizedBox(width: AppSpacing.m),
          // Nothing added or taken carries no sign: RM0.00, not −RM0.00.
          Text('${sen == 0 ? '' : sign}${Money.format(sen)}', style: TextStyle(fontWeight: weight, fontFeatures: const [FontFeature.tabularFigures()])),
        ],
      ),
    );
  }
}
