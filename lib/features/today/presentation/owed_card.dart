import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/dates/dates.dart';
import '../../../core/money/money.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/confirm_delete.dart';
import '../../../core/widgets/done_bar.dart';
import '../../../core/widgets/soft.dart';
import '../../ledger/domain/ledger_models.dart';
import '../../ledger/presentation/ledger_providers.dart';
import '../../ledger/presentation/log_sheet.dart';

/// On Today, one spend partly for others with money still owed back, like
/// a bill that is due: what is still to come, how much is back, Paid back
/// to log the next payment, and Let it go for money that will not come.
class OwedCard extends ConsumerWidget {
  const OwedCard({super.key, required this.owed, required this.name, required this.category});

  final Owed owed;

  /// What the spend was called, and its category's name.
  final String name, category;

  /// The rest becomes the user's own spending, on the day it was paid,
  /// after asking; Undo puts the split back.
  Future<void> _letGo(BuildContext context, WidgetRef ref) async {
    final e = owed.entry;
    final left = owed.left;
    final messenger = ScaffoldMessenger.of(context);
    final sure = await confirmDelete(
      context,
      title: 'Let the rest go?',
      message: 'The ${Money.format(left)} still owed for $name becomes your own $category spending on ${Dates.full(e.day)}.',
      action: 'Let it go',
    );
    if (!sure) return;
    final repo = ref.read(ledgerRepositoryProvider);
    await repo.update(e.copyWith(amount: e.amount + left, forOthers: e.forOthers - left));
    showBar(messenger, 'Let go of ${Money.format(left)} for $name', undo: () => repo.update(e));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final e = owed.entry;
    return SoftCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('$name · owed to you', style: const TextStyle(fontWeight: FontWeight.w700)),
              Text('${Money.format(owed.left)} still to come · paid ${Dates.short(e.day)}', style: TextStyle(color: c.muted, fontSize: 13)),
            ]),
          ),
          FilledButton.tonal(
            // The log sheet in Income, with this spend already picked.
            onPressed: () => showLogSheet(context, prefill: LogPrefill(isIncome: true, paybackFor: e.id, accountId: e.accountId)),
            style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
            child: const Text('Paid back'),
          ),
        ]),
        const SizedBox(height: AppSpacing.m),
        // The bar springs to each payback; the figures beside it never move
        // past what they say.
        TweenAnimationBuilder<double>(
          tween: Tween(end: owed.back / e.forOthers),
          duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : AppMotion.enter,
          curve: Curves.easeOutBack,
          builder: (context, value, _) => ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.pill),
            child: LinearProgressIndicator(value: value.clamp(0, 1), minHeight: 6, backgroundColor: c.well, color: c.good),
          ),
        ),
        Row(children: [
          Expanded(child: Text('${Money.format(owed.back)} of ${Money.format(e.forOthers)} back', style: TextStyle(color: c.muted, fontSize: 12))),
          TextButton(onPressed: () => _letGo(context, ref), style: TextButton.styleFrom(minimumSize: const Size(48, 48)), child: const Text('Let it go')),
        ]),
      ]),
    );
  }
}
