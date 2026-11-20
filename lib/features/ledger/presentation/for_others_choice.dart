import 'package:flutter/material.dart';

import '../../../core/money/money.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/validation/ringgit_cents_formatter.dart';
import '../../../core/widgets/money_field.dart';
import '../../../core/widgets/soft.dart';

/// On the log sheet, under Whose call?: whether some of a spend was for
/// other people, such as a bill paid in full for a table, and how much.
/// Their part leaves the balance with the rest but is owed back, so only
/// the user's own part counts as their spending.
class ForOthersChoice extends StatelessWidget {
  const ForOthersChoice({
    super.key,
    required this.split,
    required this.onSplit,
    required this.theirPart,
    required this.amount,
    required this.category,
    this.paidBack = 0,
  });

  final bool split;
  final ValueChanged<bool> onSplit;

  /// Holds their part as typed, filled from the right.
  final TextEditingController theirPart;

  /// All that was paid, as typed in the sheet's amount.
  final int amount;

  /// The category the user's own part counts under, by name.
  final String category;

  /// Already paid back toward their part, when editing; it can go no lower.
  final int paidBack;

  /// Why [their] cannot be their part of [amount], or null when it can.
  static String? problem(int their, int amount, int paidBack) {
    if (their == 0) return 'Type their part';
    if (their > amount) return 'More than the ${Money.format(amount)} paid';
    if (their < paidBack) return '${Money.format(paidBack)} is already paid back';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('Paid for others too?', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.muted)),
      const SizedBox(height: AppSpacing.s),
      Wrap(spacing: AppSpacing.s, runSpacing: AppSpacing.s, children: [
        ChoiceChip(key: const ValueKey('split-mine'), label: const Text('Just mine'), selected: !split, onSelected: (_) => onSplit(false)),
        ChoiceChip(key: const ValueKey('split-theirs'), label: const Text('Some was theirs'), selected: split, onSelected: (_) => onSplit(true)),
      ]),
      AnimatedSize(
        duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : AppMotion.enter,
        curve: Curves.easeOutBack,
        alignment: Alignment.topCenter,
        child: !split
            ? const SizedBox(width: double.infinity)
            : Padding(
                padding: const EdgeInsets.only(top: AppSpacing.m),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  MoneyField(
                    key: const ValueKey('their-part'),
                    controller: theirPart,
                    label: 'Their part',
                    hint: 'e.g. 30.00',
                    textInputAction: TextInputAction.done,
                    validator: (sen) => problem(sen, amount, paidBack),
                  ),
                  const SizedBox(height: AppSpacing.s),
                  ListenableBuilder(listenable: theirPart, builder: (context, _) => _Split(amount: amount, their: RinggitCentsFormatter.parse(theirPart.text), paidBack: paidBack, category: category)),
                ]),
              ),
      ),
    ]);
  }
}

/// The bill as it splits: the user's part, and what is still owed.
class _Split extends StatelessWidget {
  const _Split({required this.amount, required this.their, required this.paidBack, required this.category});

  final int amount, their, paidBack;
  final String category;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fits = ForOthersChoice.problem(their, amount, paidBack) == null;
    Widget row(String label, int sen, Color colour) => Row(children: [
          Expanded(child: Text(label, style: TextStyle(color: c.muted))),
          const SizedBox(width: AppSpacing.s),
          Text(Money.format(sen), style: TextStyle(fontWeight: FontWeight.w700, color: colour, fontFeatures: const [FontFeature.tabularFigures()])),
        ]);
    return SoftWell(
      radius: AppRadii.control,
      padding: const EdgeInsets.all(AppSpacing.m),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        row('Yours, counted as $category', fits ? amount - their : 0, c.ink),
        const SizedBox(height: AppSpacing.xs),
        row(paidBack > 0 ? 'Still owed, ${Money.format(paidBack)} already back' : 'Owed to you until paid back', fits ? their - paidBack : 0, c.primary),
        const SizedBox(height: AppSpacing.s),
        Text(
          'All ${Money.format(amount)} leaves your balance now. Only yours counts in your allowance and Insights.',
          style: TextStyle(color: c.muted, fontSize: 12.5, height: 1.4),
        ),
      ]),
    );
  }
}
