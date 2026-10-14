import 'package:flutter/material.dart';

import '../../../core/dates/dates.dart';
import '../../../core/money/money.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../domain/ledger_models.dart';
import 'category_visuals.dart';

/// One logged entry: category bubble, its name and detail, and the amount.
class EntryTile extends StatelessWidget {
  const EntryTile({super.key, required this.entry, required this.category, required this.today, this.onTap});

  final Entry entry;
  final Category? category;
  final DateTime today;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final title = entry.label ?? category?.label ?? entry.categoryKey;
    final when = entry.day == today
        ? 'Today'
        : entry.day == DateTime.utc(today.year, today.month, today.day - 1)
            ? 'Yesterday'
            : '${Dates.weekday(entry.day)} ${Dates.short(entry.day)}';
    final detail = [when, if (entry.label != null && category != null) category!.label, if (entry.note != null) entry.note!].join(' · ');
    final amount = '${entry.isIncome ? '+' : '−'}${Money.format(entry.amount)}';
    return Semantics(
      label: '$title, $amount, $detail',
      button: onTap != null,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 60),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
            child: Row(
              children: [
                CategoryBubble(categoryKey: entry.categoryKey, tint: categoryTint(category)),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                      Text(detail, style: TextStyle(fontSize: 13, color: c.muted), overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.s),
                Text(
                  amount,
                  style: TextStyle(fontWeight: FontWeight.w700, color: entry.isIncome ? c.good : c.ink, fontFeatures: const [FontFeature.tabularFigures()]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
