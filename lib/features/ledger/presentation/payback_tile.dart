import 'package:flutter/material.dart';

import '../../../core/dates/dates.dart';
import '../../../core/money/money.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../domain/ledger_models.dart';

/// Money paid back toward a spend partly for others, laid out like an entry
/// but in the primary blue, as a transfer is, so it never reads as income.
class PaybackTile extends StatelessWidget {
  const PaybackTile({super.key, required this.payback, required this.forName, required this.today});

  final Payback payback;

  /// What the spend it pays back was called, such as "Lunch".
  final String forName;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final title = 'Paid back for $forName';
    final detail = [Dates.near(payback.day, today), if (payback.payer != null) 'from ${payback.payer}', 'not income'].join(' · ');
    final amount = '+${Money.format(payback.amount)}';
    return Semantics(
      label: '$title, $amount, $detail',
      excludeSemantics: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 60),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
          child: Row(children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: c.primarySoft, borderRadius: BorderRadius.circular(14)),
              child: Icon(Icons.group_outlined, size: 20, color: c.primary),
            ),
            const SizedBox(width: AppSpacing.m),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                Text(detail, style: TextStyle(fontSize: 13, color: c.muted), overflow: TextOverflow.ellipsis),
              ]),
            ),
            const SizedBox(width: AppSpacing.s),
            Text(amount, style: TextStyle(fontWeight: FontWeight.w700, color: c.primary, fontFeatures: const [FontFeature.tabularFigures()])),
          ]),
        ),
      ),
    );
  }
}
