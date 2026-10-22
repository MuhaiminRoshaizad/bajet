import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/money/money.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_spacing.dart';
import '../../plan/presentation/plan_providers.dart';
import '../domain/ledger_models.dart';

/// How a kind of spend reads wherever it is shown.
extension SpendKindLook on SpendKind {
  String get label => switch (this) {
        SpendKind.want => 'Want',
        SpendKind.need => 'Need',
      };

  Color colour(AppColors c) => switch (this) {
        SpendKind.want => c.primary,
        SpendKind.need => c.good,
      };
}

/// Want or need for a spend, as chips like Paid from, with a line saying
/// what the choice does to the weekly allowance.
class SpendKindChoice extends ConsumerWidget {
  const SpendKindChoice({super.key, required this.kind, required this.onSelect});

  final SpendKind kind;
  final ValueChanged<SpendKind> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final cap = ref.watch(settingsProvider).value?.weeklyCap;
    final allowance = cap == null ? 'your allowance' : 'your ${Money.formatWhole(cap)}';
    final meaning = switch (kind) {
      SpendKind.want => 'A want: you chose it, so it counts toward $allowance.',
      SpendKind.need => 'A need: bought anyway or asked for, so it stays out of $allowance.',
    };
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('What kind?', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.muted)),
      const SizedBox(height: AppSpacing.s),
      Wrap(spacing: AppSpacing.s, runSpacing: AppSpacing.s, children: [
        for (final k in SpendKind.values)
          ChoiceChip(
            key: ValueKey('kind-${k.name}'),
            avatar: CircleAvatar(backgroundColor: k.colour(c), radius: 8),
            label: Text(k.label),
            selected: k == kind,
            onSelected: (_) => onSelect(k),
          ),
      ]),
      const SizedBox(height: AppSpacing.xs),
      AnimatedSwitcher(
        duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : AppMotion.fast,
        child: Text(meaning, key: ValueKey(kind), style: TextStyle(color: c.muted, fontSize: 12.5, height: 1.4)),
      ),
    ]);
  }
}
