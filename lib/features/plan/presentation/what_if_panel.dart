import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/money/money.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import 'plan_providers.dart';

/// Levers for trying a change to the plan, with Runway redrawn as they move.
/// Nothing here is saved.
class WhatIfPanel extends ConsumerWidget {
  const WhatIfPanel({super.key});

  // Ranges in sen: RM50 either way a week in RM5 steps, up to RM300 a month
  // in RM10 steps.
  static const _weekly = 5000, _weeklyStep = 500, _monthly = 30000, _monthlyStep = 1000;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final w = ref.watch(whatIfProvider);
    final controller = ref.read(whatIfProvider.notifier);
    final hasUnconfirmed = ref.watch(eventsProvider).value?.any((e) => !e.done && !e.countInProjection) ?? false;
    final weekly = w.weeklyChange == 0
        ? 'No change'
        : '${w.weeklyChange > 0 ? '+' : '−'}${Money.formatWhole(w.weeklyChange.abs())} a week';
    final monthly = w.monthlyCost == 0 ? 'None' : '${Money.formatWhole(w.monthlyCost)} a month';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(child: Text('What if…', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16))),
            if (!w.isNone) TextButton(onPressed: controller.reset, style: TextButton.styleFrom(minimumSize: const Size(48, 48)), child: const Text('Reset')),
          ],
        ),
        Text('Try a change and see buy day move. Nothing here is saved.', style: TextStyle(color: c.muted, fontSize: 13)),
        const SizedBox(height: AppSpacing.m),
        _Lever(label: 'Spend more or less each week', value: weekly),
        // Runs both ways from no change, so the track is one colour throughout
        // rather than filling from the left as if the middle were half.
        SliderTheme(
          data: SliderTheme.of(context).copyWith(activeTrackColor: SliderTheme.of(context).inactiveTrackColor),
          child: Slider(
          value: w.weeklyChange.toDouble(),
          min: -_weekly.toDouble(),
          max: _weekly.toDouble(),
          divisions: 2 * _weekly ~/ _weeklyStep,
          label: weekly,
          semanticFormatterCallback: (_) => weekly,
          onChanged: (v) => controller.change(w.copyWith(weeklyChange: v.round())),
          ),
        ),
        _Lever(label: 'A new monthly cost, from the 1st', value: monthly),
        Slider(
          value: w.monthlyCost.toDouble(),
          max: _monthly.toDouble(),
          divisions: _monthly ~/ _monthlyStep,
          label: monthly,
          semanticFormatterCallback: (_) => monthly,
          onChanged: (v) => controller.change(w.copyWith(monthlyCost: v.round())),
        ),
        if (hasUnconfirmed)
          MergeSemantics(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Count money not yet confirmed'),
                      Text('Planned events marked as not counted', style: TextStyle(color: c.muted, fontSize: 13)),
                    ],
                  ),
                ),
                Switch(value: w.countUnconfirmed, onChanged: (v) => controller.change(w.copyWith(countUnconfirmed: v))),
              ],
            ),
          ),
      ],
    );
  }
}

class _Lever extends StatelessWidget {
  const _Lever({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(child: Text(label)),
          const SizedBox(width: AppSpacing.s),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontFeatures: [FontFeature.tabularFigures()])),
        ],
      );
}
