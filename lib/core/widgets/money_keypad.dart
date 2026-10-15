import 'package:flutter/material.dart';

import '../money/money.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'soft.dart';

/// The cashier keys: digits fill an amount from the right, `00` adds two
/// zeros, and the last key takes the newest digit off.
class MoneyKeypad extends StatelessWidget {
  const MoneyKeypad({super.key, required this.onKey});

  /// Called with `'0'`–`'9'`, `'00'` or `'del'`.
  final ValueChanged<String> onKey;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    const keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '00', '0', 'del'];
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      // Room around each key for its shadow.
      padding: const EdgeInsets.all(AppSpacing.xs),
      mainAxisSpacing: AppSpacing.m,
      crossAxisSpacing: AppSpacing.m,
      childAspectRatio: 2.2,
      children: [
        for (final k in keys)
          SoftButton(
            onTap: () => onKey(k),
            child: Center(
              child: k == 'del'
                  ? Icon(Icons.backspace_outlined, color: c.ink, semanticLabel: 'Delete digit')
                  : Text(k, style: TextStyle(fontSize: 21, fontWeight: FontWeight.w600, color: c.ink)),
            ),
          ),
      ],
    );
  }
}

/// The amount after [key] is pressed on [sen], never above [maxSen].
int pressMoneyKey(int sen, String key, {required int maxSen}) {
  final next = switch (key) {
    'del' => sen ~/ 10,
    '00' => sen * 100,
    _ => sen * 10 + int.parse(key),
  };
  return next > maxSen ? sen : next;
}

/// Asks for an amount on the app's own keypad, starting from [sen]. Returns
/// the new amount in sen, or null if the sheet is dismissed unchanged.
Future<int?> showMoneyKeypad(BuildContext context, {required String label, required int sen, String? helper, int maxSen = 100000000}) =>
    showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _MoneyKeypadSheet(label: label, initial: sen, helper: helper, maxSen: maxSen),
    );

class _MoneyKeypadSheet extends StatefulWidget {
  const _MoneyKeypadSheet({required this.label, required this.initial, required this.helper, required this.maxSen});

  final String label;
  final int initial;
  final String? helper;
  final int maxSen;

  @override
  State<_MoneyKeypadSheet> createState() => _MoneyKeypadSheetState();
}

class _MoneyKeypadSheetState extends State<_MoneyKeypadSheet> {
  late int _sen = widget.initial;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.l, 0, AppSpacing.l, AppSpacing.l),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const SizedBox(width: AppSpacing.xs),
              Expanded(child: Text(widget.label, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700))),
              if (_sen > 0) TextButton(onPressed: () => setState(() => _sen = 0), child: const Text('Clear')),
            ],
          ),
          const SizedBox(height: AppSpacing.s),
          SoftWell(
            radius: AppRadii.card,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.s, horizontal: AppSpacing.l),
            child: Semantics(
              liveRegion: true,
              label: '${widget.label} ${Money.format(_sen)}',
              excludeSemantics: true,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  Money.format(_sen),
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -1,
                    color: _sen == 0 ? c.muted : c.ink,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
          ),
          if (widget.helper != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xs, AppSpacing.s, AppSpacing.xs, 0),
              child: Text(widget.helper!, style: TextStyle(color: c.muted, fontSize: 13, height: 1.4)),
            ),
          const SizedBox(height: AppSpacing.m),
          MoneyKeypad(onKey: (k) => setState(() => _sen = pressMoneyKey(_sen, k, maxSen: widget.maxSen))),
          const SizedBox(height: AppSpacing.m),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(_sen),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}
