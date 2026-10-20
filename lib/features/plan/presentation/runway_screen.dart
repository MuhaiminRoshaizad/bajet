import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../../core/dates/dates.dart';
import '../../../core/money/money.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/rise_in.dart';
import '../../../core/widgets/soft.dart';
import '../../../core/widgets/under_bar.dart';
import '../domain/upcoming.dart';
import 'plan_providers.dart';
import 'runway_chart.dart';
import 'runway_sums.dart';
import 'runway_upcoming.dart';
import 'what_if_panel.dart';

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
    final whatIf = ref.watch(whatIfProvider);
    final projection = ref.watch(projectionWithProvider(whatIf));
    final planned = ref.watch(projectionProvider)?.goals.firstOrNull?.leftAfterBuying;
    final settings = ref.watch(settingsProvider).value;
    final items = ref.watch(upcomingProvider) ?? const [];
    final outcome = projection?.goals.firstOrNull;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: EdgeInsets.fromLTRB(AppSpacing.l, AppSpacing.s, AppSpacing.l, underBar(context)),
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
              spacing: AppSpacing.l,
              children: [
                SoftCard(
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
                  SoftCard(
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
                        if (!whatIf.isNone && planned != null) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            outcome.leftAfterBuying == planned
                                ? 'The same as the plan'
                                : '${outcome.leftAfterBuying > planned ? '+' : '−'}${Money.format((outcome.leftAfterBuying - planned).abs())} compared with the plan',
                            style: TextStyle(color: c.ink, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ],
                    ),
                  )
                else
                  SoftWell(
                    radius: AppRadii.card,
                    padding: const EdgeInsets.all(AppSpacing.l + 2),
                    child: Text('Add a goal to see what would be left after buying it.', style: TextStyle(color: c.ink)),
                  ),
                if (outcome != null) RunwaySumsCard(outcome: outcome),
                if (outcome != null) const SoftCard(child: WhatIfPanel()),
                Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.xs, top: AppSpacing.s),
                  child: Text('Coming up', style: TextStyle(color: c.muted, fontWeight: FontWeight.w600)),
                ),
                UpcomingCard(items: items),
              ],
            ),
        ],
      ),
    );
  }
}
