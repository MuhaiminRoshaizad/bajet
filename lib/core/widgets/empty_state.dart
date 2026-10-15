import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'soft.dart';

/// What a screen shows when it has nothing to show: an icon pressed into the
/// surface, a line saying what is missing, one saying what to do, and the
/// action that does it. It fills the space it is given and sits a little
/// above the middle, since true centre looks low above the bottom bar.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.secondaryLabel,
    this.onSecondary,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return LayoutBuilder(
      // Scrolls only when large text no longer fits, so nothing is cut off.
      builder: (context, box) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: box.maxHeight),
          child: Align(
            alignment: const Alignment(0, -0.2),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.xxl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox.square(
                      dimension: 72,
                      child: SoftWell(circle: true, padding: EdgeInsets.zero, child: Center(child: Icon(icon, size: 30, color: c.primary))),
                    ),
                    const SizedBox(height: AppSpacing.l),
                    Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: AppSpacing.xs),
                    Text(message, textAlign: TextAlign.center, style: TextStyle(color: c.muted, height: 1.45)),
                    if (actionLabel != null) ...[
                      const SizedBox(height: AppSpacing.xl),
                      FilledButton(
                        onPressed: onAction,
                        style: FilledButton.styleFrom(minimumSize: const Size(200, 52)),
                        child: Text(actionLabel!),
                      ),
                    ],
                    if (secondaryLabel != null) ...[
                      const SizedBox(height: AppSpacing.s),
                      TextButton(onPressed: onSecondary, style: TextButton.styleFrom(minimumSize: const Size(48, 48)), child: Text(secondaryLabel!)),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
