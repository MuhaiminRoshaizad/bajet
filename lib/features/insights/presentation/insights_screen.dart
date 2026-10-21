import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/database_provider.dart';
import '../../../core/dates/dates.dart';
import '../../../core/money/money.dart';
import '../../../core/navigation/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/rise_in.dart';
import '../../../core/widgets/soft.dart';
import '../../../core/widgets/under_bar.dart';
import '../../ledger/domain/ledger_models.dart';
import '../../ledger/presentation/ledger_providers.dart';
import '../../ledger/presentation/log_sheet.dart';
import '../../plan/presentation/plan_providers.dart';
import '../domain/insights.dart';
import 'category_ring.dart';
import 'insights_providers.dart';
import 'period_picker.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(insightsPeriodProvider);
    final i = ref.watch(insightsProvider);
    final categories = {for (final x in ref.watch(categoriesProvider).value ?? const <Category>[]) x.key: x};

    final header = [
          SizedBox(
            height: 48,
            child: Row(
              children: [
                Text('Insights', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                const Spacer(),
                IconButton(
                  onPressed: () => context.push('${Routes.report}?period=${period.period.name}&offset=${period.offset}'),
                  icon: const Icon(Icons.ios_share_rounded),
                  tooltip: 'Share a report',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s),
          PeriodPicker(range: period, onChanged: ref.read(insightsPeriodProvider.notifier).show),
          const SizedBox(height: AppSpacing.l),
    ];
    const padding = EdgeInsets.fromLTRB(AppSpacing.l, AppSpacing.s, AppSpacing.l, 0);

    if (i != null && i.isEmpty) {
      return SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(padding: padding, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: header)),
            Expanded(
              child: PeriodSlide(
                range: period,
                child: EmptyState(
                icon: Icons.insights_rounded,
                title: 'Nothing logged ${_since(i, period)}',
                message: 'What you log shows up here, by category and by day.',
                actionLabel: 'Log a spend',
                onAction: () => showLogSheet(context),
                ),
              ),
            ),
          ],
        ),
      );
    }
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: padding.copyWith(bottom: underBar(context)),
        children: [
          ...header,
          if (i != null)
            PeriodSlide(
              range: period,
              child: RiseIn(
                spacing: AppSpacing.l,
                children: [
                  _Totals(i: i),
                  SoftCard(child: _Split(i: i)),
                  if (i.outByCategory.isNotEmpty)
                    SoftCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const _Title('Where the money went'),
                          const SizedBox(height: AppSpacing.l),
                          CategoryRing(
                            byCategory: i.outByCategory,
                            categories: categories,
                            entries: i.outEntries,
                            today: ref.watch(todayProvider),
                            onOpenEntry: (e) => showLogSheet(context, editing: e),
                          ),
                        ],
                      ),
                    ),
                  SoftCard(child: _LastDays(days: i.lastDays)),
                  SoftCard(child: _Habits(i: i)),
                  const _GoalProgress(),
                ],
              ),
            ),
        ],
      ),
    );
  }

  static String _since(Insights i, InsightsRange r) => switch (r.period) {
        InsightsPeriod.week => r.offset == 0 ? 'this week' : 'that week',
        InsightsPeriod.month => r.offset == 0 ? 'this month' : 'in ${Dates.monthYear(i.to)}',
        InsightsPeriod.all => 'since ${Dates.full(i.from)}',
      };
}

class _Title extends StatelessWidget {
  const _Title(this.text, {this.trailing});

  final String text;
  final String? trailing;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(flex: 3, child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16))),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.s),
            Expanded(flex: 2, child: Text(trailing!, textAlign: TextAlign.end, style: TextStyle(color: context.colors.muted, fontSize: 13))),
          ],
        ],
      );
}

class _Totals extends StatelessWidget {
  const _Totals({required this.i});

  final Insights i;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final share = i.moneyIn == 0 ? null : (i.kept / i.moneyIn * 100).round();
    final tiles = [
      _Tile(label: 'Money in', value: Money.format(i.moneyIn), colour: c.good),
      _Tile(label: 'Money out', value: Money.format(i.moneyOut), colour: c.ink),
      _Tile(
        label: i.kept >= 0 ? 'Kept' : 'Spent more than came in',
        value: Money.format(i.kept.abs()),
        colour: i.kept >= 0 ? c.keep : c.bad,
        note: share != null && i.kept >= 0 ? '$share% of what came in' : null,
      ),
      _Tile(label: 'Untracked', value: Money.format(i.untrackedOut), colour: i.untrackedOut > 0 ? c.bad : c.ink, note: 'found at check-ins'),
    ];
    return Column(
      children: [
        for (var row = 0; row < 2; row++) ...[
          if (row > 0) const SizedBox(height: AppSpacing.l),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [Expanded(child: tiles[row * 2]), const SizedBox(width: AppSpacing.l), Expanded(child: tiles[row * 2 + 1])],
            ),
          ),
        ],
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.label, required this.value, required this.colour, this.note});

  final String label;
  final String value;
  final Color colour;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SoftCard(
      padding: const EdgeInsets.all(AppSpacing.l),
      radius: AppRadii.card - 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: c.muted, fontSize: 13)),
          const SizedBox(height: AppSpacing.xs),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: TextStyle(color: colour, fontSize: 20, fontWeight: FontWeight.w700, fontFeatures: const [FontFeature.tabularFigures()])),
          ),
          if (note != null) Text(note!, style: TextStyle(color: c.muted, fontSize: 12)),
        ],
      ),
    );
  }
}

/// Money out as one bar in three parts, each also named in words below.
class _Split extends StatelessWidget {
  const _Split({required this.i});

  final Insights i;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final parts = [
      ('Fixed', 'bills, goals, events', i.fixedOut, c.tintInk(Tint.teal)),
      ('Flexible', 'day to day', i.flexibleOut, c.tintInk(Tint.apricot)),
      if (i.untrackedOut > 0) ('Untracked', 'not logged', i.untrackedOut, c.bad),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Title('Fixed and flexible', trailing: 'of ${Money.format(i.moneyOut)}'),
        const SizedBox(height: AppSpacing.m),
        Semantics(
          label: [for (final p in parts) '${p.$1} ${Money.format(p.$3)}'].join(', '),
          excludeSemantics: true,
          child: SizedBox(
            height: 16,
            child: SoftWell(
              radius: AppRadii.pill,
              padding: const EdgeInsets.all(2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (n, p) in parts.where((p) => p.$3 > 0).indexed) ...[
                    if (n > 0) const SizedBox(width: 2),
                    Expanded(
                      flex: math.max(1, (p.$3 / math.max(1, i.moneyOut) * 1000).round()),
                      child: DecoratedBox(decoration: BoxDecoration(color: p.$4, borderRadius: BorderRadius.circular(AppRadii.pill))),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.m),
        for (final p in parts)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Row(
              children: [
                Container(width: 10, height: 10, decoration: BoxDecoration(color: p.$4, shape: BoxShape.circle)),
                const SizedBox(width: AppSpacing.s),
                Expanded(child: Text('${p.$1} · ${p.$2}', style: const TextStyle(fontSize: 13))),
                Text(Money.format(p.$3), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, fontFeatures: [FontFeature.tabularFigures()])),
              ],
            ),
          ),
      ],
    );
  }
}

/// Fourteen bars of flexible spending, each against its own day's plan:
/// rose when over, blue when within, a short mark where the plan sat.
class _LastDays extends StatelessWidget {
  const _LastDays({required this.days});

  final List<DayAgainstPlan> days;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final over = days.where((d) => d.over).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Title('Last 14 days', trailing: over == 0 ? 'every day within plan' : '$over ${over == 1 ? 'day' : 'days'} over plan'),
        const SizedBox(height: AppSpacing.m),
        Semantics(
          label: 'Flexible spending for the last 14 days. ${[for (final d in days) '${Dates.short(d.date)} ${Money.format(d.spent)}'].join(', ')}',
          excludeSemantics: true,
          child: SizedBox(
            height: 120,
            child: CustomPaint(painter: _BarsPainter(days: days, within: c.primary, over: c.bad, plan: c.muted, empty: c.well)),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Text(Dates.short(days.first.date), style: TextStyle(color: c.muted, fontSize: 11)),
            const Spacer(),
            Text('Today', style: TextStyle(color: c.muted, fontSize: 11)),
          ],
        ),
      ],
    );
  }
}

class _BarsPainter extends CustomPainter {
  _BarsPainter({required this.days, required this.within, required this.over, required this.plan, required this.empty});

  final List<DayAgainstPlan> days;
  final Color within, over, plan, empty;

  @override
  void paint(Canvas canvas, Size size) {
    final top = days.map((d) => math.max(d.spent, d.planned)).fold(1, math.max) * 1.15;
    final slot = size.width / days.length;
    final bar = slot * 0.62;
    for (final (i, d) in days.indexed) {
      final x = i * slot + (slot - bar) / 2;
      final h = d.spent == 0 ? 3.0 : math.max(3.0, size.height * d.spent / top);
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x, size.height - h, bar, h), const Radius.circular(4)),
        Paint()..color = d.spent == 0 ? empty : (d.over ? over : within),
      );
      if (d.planned > 0) {
        final y = size.height - size.height * d.planned / top;
        canvas.drawLine(Offset(x - 2, y), Offset(x + bar + 2, y), Paint()
          ..color = plan
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round);
      }
    }
  }

  @override
  bool shouldRepaint(_BarsPainter old) => old.days != days || old.within != within;
}

class _Habits extends StatelessWidget {
  const _Habits({required this.i});

  final Insights i;

  @override
  Widget build(BuildContext context) {
    final cells = [
      ('${i.zeroSpendDays}', 'no-spend days'),
      ('${i.daysWithinPlan}/${i.daysSoFar}', 'days within plan'),
      (i.fullWeeks == 0 ? '–' : '${i.weeksUnderAllowance}/${i.fullWeeks}', 'weeks under allowance'),
      ('${i.daysLogged}', 'days with a log'),
      (i.frequent == null ? '–' : Money.format(i.frequent!.average), i.frequent == null ? 'usual spend' : 'usual ${i.frequent!.label.toLowerCase()}'),
      (i.biggest == null ? '–' : Money.format(i.biggest!.amount), 'biggest extra'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Title('Habits'),
        const SizedBox(height: AppSpacing.m),
        for (var row = 0; row < 2; row++)
          Padding(
            padding: EdgeInsets.only(top: row == 0 ? 0 : AppSpacing.m),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [for (final cell in cells.sublist(row * 3, row * 3 + 3)) Expanded(child: _Habit(value: cell.$1, label: cell.$2))],
            ),
          ),
      ],
    );
  }
}

class _Habit extends StatelessWidget {
  const _Habit({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, fontFeatures: [FontFeature.tabularFigures()])),
          ),
          Text(label, textAlign: TextAlign.center, style: TextStyle(color: context.colors.muted, fontSize: 12)),
        ],
      );
}

/// How much of the first goal's price, plus the buffer, is already there.
class _GoalProgress extends ConsumerWidget {
  const _GoalProgress();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final goal = ref.watch(goalsProvider).value?.firstOrNull;
    final balance = ref.watch(balanceProvider).value;
    final buffer = ref.watch(settingsProvider).value?.buffer;
    if (goal == null || balance == null || buffer == null) return const SizedBox.shrink();
    final needed = goal.price + buffer;
    final share = (balance / needed).clamp(0.0, 1.0);
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Title('Toward ${goal.name}', trailing: '${(share * 100).round()}%'),
          const SizedBox(height: AppSpacing.m),
          Semantics(label: '${(share * 100).round()} percent of what is needed', excludeSemantics: true, child: SoftMeter(value: share, color: c.keep)),
          const SizedBox(height: AppSpacing.s),
          Text('${Money.format(math.max(0, balance))} of ${Money.format(needed)} needed', style: TextStyle(color: c.keep)),
          if (buffer > 0) Text('The price plus ${Money.formatWhole(buffer)} to keep', style: TextStyle(color: c.muted, fontSize: 13)),
        ],
      ),
    );
  }
}
