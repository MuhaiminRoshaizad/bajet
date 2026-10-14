import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../../core/dates/dates.dart';
import '../../../core/money/money.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/rise_in.dart';
import '../domain/upcoming.dart';
import 'plan_providers.dart';
import 'runway_chart.dart';

final upcomingProvider = Provider<List<UpcomingItem>?>((ref) {
  final projection = ref.watch(projectionProvider);
  final recurring = ref.watch(recurringProvider).value;
  final events = ref.watch(eventsProvider).value;
  final goals = ref.watch(goalsProvider).value;
  if (projection == null || recurring == null || events == null || goals == null) return null;
  return upcoming(
    recurring: recurring,
    events: events,
    goals: goals,
    from: ref.watch(todayProvider),
    to: projection.days.last.date,
  );
});

class RunwayScreen extends ConsumerWidget {
  const RunwayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final projection = ref.watch(projectionProvider);
    final settings = ref.watch(settingsProvider).value;
    final items = ref.watch(upcomingProvider) ?? const [];
    final outcome = projection?.goals.firstOrNull;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.l, AppSpacing.s, AppSpacing.l, AppSpacing.xxl),
        children: [
          SizedBox(
            height: 48,
            child: Row(
              children: [
                Text('Runway', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                const Spacer(),
                if (outcome != null) Text('to ${Dates.full(outcome.goal.targetDate)}', style: TextStyle(color: c.muted)),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.m),
          if (projection != null && settings != null)
            RiseIn(
              spacing: AppSpacing.m,
              children: [
                _Panel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        outcome == null ? 'Your balance over the next 30 days' : 'Your balance from now to buy day',
                        style: TextStyle(color: c.muted, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: AppSpacing.m),
                      RunwayChart(days: projection.days, buffer: settings.buffer, onTrack: outcome?.onTrack ?? true),
                    ],
                  ),
                ),
                if (outcome != null)
                  _Panel(
                    color: outcome.onTrack ? c.keepSurface : c.badSurface,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Left after buying ${outcome.goal.name}', style: TextStyle(color: outcome.onTrack ? c.keep : c.bad, fontWeight: FontWeight.w600)),
                        const SizedBox(height: AppSpacing.xs),
                        Text(Money.format(outcome.leftAfterBuying), style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700, letterSpacing: -0.5)),
                        Text(
                          outcome.onTrack
                              ? '${Money.format(outcome.leftAfterBuying - settings.buffer)} above your ${Money.formatWhole(settings.buffer)} buffer'
                              : '${Money.format(settings.buffer - outcome.leftAfterBuying)} short of your ${Money.formatWhole(settings.buffer)} buffer',
                          style: TextStyle(color: outcome.onTrack ? c.keep : c.bad),
                        ),
                      ],
                    ),
                  )
                else
                  _Panel(
                    color: c.primarySoft,
                    child: Text('Add a goal to see what would be left after buying it.', style: TextStyle(color: c.ink)),
                  ),
                Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.xs, top: AppSpacing.s),
                  child: Text('Coming up', style: TextStyle(color: c.muted, fontWeight: FontWeight.w600)),
                ),
                _Panel(
                  child: items.isEmpty
                      ? Text('No bills, income or events planned yet.', style: TextStyle(color: c.muted))
                      : Column(
                          children: [
                            for (final (i, item) in items.take(10).indexed) ...[
                              if (i > 0) Divider(color: c.line),
                              _UpcomingRow(item: item),
                            ],
                          ],
                        ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _UpcomingRow extends StatelessWidget {
  const _UpcomingRow({required this.item});

  final UpcomingItem item;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final income = item.signedAmount > 0;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                Text(
                  [Dates.full(item.date), if (!item.counted) 'not counted', if (item.isGoal) 'buy day'].join(' · '),
                  style: TextStyle(color: c.muted, fontSize: 13),
                ),
              ],
            ),
          ),
          Text(
            '${income ? '+' : '−'}${Money.format(item.signedAmount.abs())}',
            style: TextStyle(fontWeight: FontWeight.w700, color: income ? c.good : c.ink, fontFeatures: const [FontFeature.tabularFigures()]),
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child, this.color});

  final Widget child;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.l + 2),
      decoration: BoxDecoration(
        color: color ?? c.card,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: dark && color == null ? Border.all(color: c.line) : null,
      ),
      child: child,
    );
  }
}
