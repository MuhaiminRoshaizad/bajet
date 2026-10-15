import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../../core/dates/dates.dart';
import '../../../core/money/money.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/soft.dart';
import '../../ledger/domain/ledger_models.dart';
import '../../ledger/presentation/category_visuals.dart';
import '../../ledger/presentation/ledger_providers.dart';
import '../domain/upcoming.dart';

/// What is planned before buy day, one heading per date so a day with many
/// bills names its date once, with their total. The next 30 days show first; the rest open on
/// request.
class UpcomingCard extends ConsumerStatefulWidget {
  const UpcomingCard({super.key, required this.items});

  final List<UpcomingItem> items;

  @override
  ConsumerState<UpcomingCard> createState() => _UpcomingCardState();
}

class _UpcomingCardState extends ConsumerState<UpcomingCard> {
  static const _firstDays = 30;
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    if (widget.items.isEmpty) return SoftCard(child: Text('No bills, income or events planned yet.', style: TextStyle(color: c.muted)));

    final categories = {for (final x in ref.watch(categoriesProvider).value ?? const <Category>[]) x.key: x};
    final today = ref.watch(todayProvider);
    final cutoff = DateTime.utc(today.year, today.month, today.day + _firstDays);
    final groups = <(DateTime, DateTime?), List<UpcomingItem>>{};
    for (final item in widget.items) {
      (groups[(item.date, item.lastDate)] ??= []).add(item);
    }
    final all = groups.entries.toList();
    // Always at least the first date, even when it is more than 30 days off.
    final soon = all.where((g) => !g.key.$1.isAfter(cutoff)).length;
    final shown = _showAll ? all : all.take(soon == 0 ? 1 : soon).toList();

    return SoftCard(
      padding: const EdgeInsets.fromLTRB(AppSpacing.l + 2, AppSpacing.m, AppSpacing.l + 2, AppSpacing.s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, group) in shown.indexed) ...[
            if (i > 0) const SizedBox(height: AppSpacing.m),
            // A day's total is worth showing only when more than one thing lands on it.
            _DateHeading(first: group.key.$1, last: group.key.$2, net: group.value.length > 1 ? group.value.fold<int>(0, (s, x) => s + x.signedAmount) : null),
            for (final item in group.value) _UpcomingRow(item: item, category: categories[item.categoryKey]),
          ],
          if (shown.length < all.length)
            TextButton(
              onPressed: () => setState(() => _showAll = true),
              style: TextButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              child: Text('Show all until buy day (${all.length - shown.length} more ${all.length - shown.length == 1 ? 'date' : 'dates'})'),
            ),
        ],
      ),
    );
  }
}

class _DateHeading extends StatelessWidget {
  const _DateHeading({required this.first, required this.last, required this.net});

  final DateTime first;
  final DateTime? last;
  final int? net;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final style = TextStyle(color: c.muted, fontWeight: FontWeight.w700, fontSize: 13, fontFeatures: const [FontFeature.tabularFigures()]);
    return Semantics(
      header: true,
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
        child: Row(
          children: [
            Expanded(child: Text(last == null ? '${Dates.weekday(first)} ${Dates.full(first)}' : Dates.span(first, last!), style: style)),
            if (net case final net?) Text('${net > 0 ? '+' : net < 0 ? '−' : ''}${Money.format(net.abs())}', style: style.copyWith(color: net > 0 ? c.good : c.muted)),
          ],
        ),
      ),
    );
  }
}

class _UpcomingRow extends StatelessWidget {
  const _UpcomingRow({required this.item, required this.category});

  final UpcomingItem item;
  final Category? category;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final income = item.signedAmount > 0;
    final tint = item.isGoal ? Tint.apricot : categoryTint(category);
    final icon = item.isGoal ? Icons.flag_outlined : item.categoryKey == null ? Icons.event_outlined : categoryIcon(item.categoryKey!);
    final note = [if (item.isGoal) 'buy day', if (!item.counted) 'not counted'].join(' · ');
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 52),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: c.tintFill(tint), borderRadius: BorderRadius.circular(AppRadii.small - 2)),
            child: Icon(icon, size: 19, color: c.tintInk(tint)),
          ),
          const SizedBox(width: AppSpacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                if (note.isNotEmpty) Text(note, style: TextStyle(color: c.muted, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.m),
          Text(
            '${income ? '+' : '−'}${Money.format(item.signedAmount.abs())}',
            style: TextStyle(fontWeight: FontWeight.w700, color: income ? c.good : c.ink, fontFeatures: const [FontFeature.tabularFigures()]),
          ),
        ],
      ),
    );
  }
}
