import 'package:flutter/material.dart';

import '../../../core/money/money.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_spacing.dart';
import '../../ledger/domain/ledger_models.dart';
import '../../ledger/presentation/entry_drawer.dart';
import '../../ledger/presentation/log_sheet.dart';
import '../../ledger/presentation/spend_kind_choice.dart';

/// Under the week dial: what went on needs this week, which the dial leaves
/// out, so nothing spent is hidden. A tap opens those entries under it.
class WeekNeeds extends StatefulWidget {
  const WeekNeeds({super.key, required this.needs, required this.cap, required this.categories, required this.today});

  /// This week's needs, newest first.
  final List<Entry> needs;
  final int cap;
  final Map<String, Category> categories;
  final DateTime today;

  @override
  State<WeekNeeds> createState() => _WeekNeedsState();
}

class _WeekNeedsState extends State<WeekNeeds> {
  var _open = false;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final still = MediaQuery.disableAnimationsOf(context);
    final total = widget.needs.fold(0, (s, e) => s + e.amount);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const SizedBox(height: AppSpacing.s),
      Semantics(
        button: true,
        expanded: _open,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.control),
          onTap: () => setState(() => _open = !_open),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  CircleAvatar(backgroundColor: SpendKind.need.colour(c), radius: 5),
                  const SizedBox(width: AppSpacing.s),
                  Text('Needs ', style: TextStyle(color: c.muted)),
                  Text(Money.format(total), style: const TextStyle(fontWeight: FontWeight.w600, fontFeatures: [FontFeature.tabularFigures()])),
                  AnimatedRotation(
                    turns: _open ? 0.5 : 0,
                    duration: still ? Duration.zero : AppMotion.enter,
                    curve: Curves.easeOutBack,
                    child: Icon(Icons.expand_more_rounded, size: 18, color: c.muted),
                  ),
                ]),
                Text('Also this week, not counted in your ${Money.formatWhole(widget.cap)}', textAlign: TextAlign.center, style: TextStyle(color: c.muted, fontSize: 12)),
              ]),
            ),
          ),
        ),
      ),
      AnimatedSize(
        duration: still ? Duration.zero : AppMotion.enter,
        curve: Curves.easeOutBack,
        alignment: Alignment.topCenter,
        child: _open
            ? EntryDrawer(entries: widget.needs, categories: widget.categories, today: widget.today, onOpen: (e) => showLogSheet(context, editing: e))
            : const SizedBox(width: double.infinity),
      ),
    ]);
  }
}
