import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'soft.dart';

/// Rows of list tiles on one raised card, with a divider between rows. With
/// a [label] the card is headed by it, and [labelTrailing] sits at the
/// heading's other end, such as a total.
class CardGroup extends StatelessWidget {
  const CardGroup({super.key, required this.children, this.label, this.labelTrailing});

  final List<Widget> children;
  final String? label;
  final Widget? labelTrailing;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final shape = BorderRadius.circular(AppRadii.card);
    // A raised card whose inside is a Material, so each row's ink ripple
    // paints on it.
    final card = DecoratedBox(
      decoration: BoxDecoration(borderRadius: shape, boxShadow: softShadows(c, AppDepth.card)),
      child: Material(
        color: c.background,
        borderRadius: shape,
        clipBehavior: Clip.antiAlias,
        child: Column(children: [for (final (i, row) in children.indexed) ...[if (i > 0) Divider(color: c.line, indent: AppSpacing.l), row]]),
      ),
    );
    if (label == null) return card;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xs, 0, AppSpacing.xs, AppSpacing.s),
          child: Row(
            children: [
              Expanded(child: Semantics(header: true, child: Text(label!, style: TextStyle(color: c.muted, fontWeight: FontWeight.w700, fontSize: 13)))),
              ?labelTrailing,
            ],
          ),
        ),
        card,
      ],
    );
  }
}
