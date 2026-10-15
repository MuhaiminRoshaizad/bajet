import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/soft.dart';

/// One of the logger's optional details, the day or the receipt: a raised
/// tile like the category tiles, with a small label and its current value,
/// so both settings read as a matched pair.
class DetailTile extends StatelessWidget {
  const DetailTile({super.key, required this.label, required this.value, required this.leading, required this.onTap});

  final String label;
  final String value;
  final Widget leading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SoftButton(
      onTap: onTap,
      semanticLabel: '$label, $value',
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.s + 2),
      child: Row(
        children: [
          SizedBox.square(dimension: 36, child: Center(child: leading)),
          const SizedBox(width: AppSpacing.s),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.muted)),
                Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w700, color: c.ink)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
