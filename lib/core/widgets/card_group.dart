import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'soft.dart';

/// Rows of list tiles on one raised card, with a divider between rows.
class CardGroup extends StatelessWidget {
  const CardGroup({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final shape = BorderRadius.circular(AppRadii.card);
    // A raised card whose inside is a Material, so each row's ink ripple
    // paints on it.
    return DecoratedBox(
      decoration: BoxDecoration(borderRadius: shape, boxShadow: softShadows(c, AppDepth.card)),
      child: Material(
        color: c.background,
        borderRadius: shape,
        clipBehavior: Clip.antiAlias,
        child: Column(children: [for (final (i, row) in children.indexed) ...[if (i > 0) Divider(color: c.line, indent: AppSpacing.l), row]]),
      ),
    );
  }
}
