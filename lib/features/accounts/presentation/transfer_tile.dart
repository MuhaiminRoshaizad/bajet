import 'package:flutter/material.dart';

import '../../../core/dates/dates.dart';
import '../../../core/money/money.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../domain/account_models.dart';

/// One transfer, laid out like an entry but in the primary blue, so it never
/// reads as spending. Seen from one account ([seenFrom]) it says where the
/// money went or came from, and carries a sign.
class TransferTile extends StatelessWidget {
  const TransferTile({super.key, required this.transfer, required this.names, required this.today, this.seenFrom});

  final Transfer transfer;

  /// Account names by id.
  final Map<int, String> names;
  final DateTime today;

  /// The account whose activity this is, if any.
  final int? seenFrom;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final from = names[transfer.fromId] ?? 'An account';
    final to = names[transfer.toId] ?? 'an account';
    final out = seenFrom == transfer.fromId;
    final title = switch (seenFrom) {
      null => '$from → $to',
      _ => out ? 'Moved to $to' : 'Moved from $from',
    };
    final when = transfer.day == today
        ? 'Today'
        : transfer.day == DateTime.utc(today.year, today.month, today.day - 1)
            ? 'Yesterday'
            : '${Dates.weekday(transfer.day)} ${Dates.short(transfer.day)}';
    final detail = [when, 'Moved, not spent', if (transfer.note != null) transfer.note!].join(' · ');
    final amount = '${seenFrom == null ? '' : out ? '−' : '+'}${Money.format(transfer.amount)}';
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
              child: Icon(Icons.swap_horiz_rounded, size: 20, color: c.primary),
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
