import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// One choice in a [SpringMenuButton]'s menu.
class SpringMenuItem<T> {
  const SpringMenuItem({required this.value, required this.icon, required this.label, this.destructive = false});

  final T value;
  final IconData icon;
  final String label;

  /// Shown in the warning colour, for a choice that removes something.
  final bool destructive;
}

/// The ⋮ in a screen's header. Its menu grows out of the button's corner,
/// passing its size a little before it settles, and closes on a tap
/// outside it. With the system's reduce-motion setting on it simply appears.
class SpringMenuButton<T> extends StatelessWidget {
  const SpringMenuButton({super.key, required this.items, required this.onSelected, this.tooltip = 'More'});

  final List<SpringMenuItem<T>> items;
  final ValueChanged<T> onSelected;
  final String tooltip;

  Future<void> _open(BuildContext context) async {
    final box = context.findRenderObject()! as RenderBox;
    final anchor = box.localToGlobal(Offset.zero) & box.size;
    final picked = await Navigator.of(context).push<T>(_SpringMenuRoute<T>(anchor: anchor, items: items));
    if (picked != null) onSelected(picked);
  }

  @override
  Widget build(BuildContext context) => Builder(
        builder: (context) => IconButton(onPressed: () => _open(context), icon: const Icon(Icons.more_vert_rounded), tooltip: tooltip),
      );
}

class _SpringMenuRoute<T> extends PopupRoute<T> {
  _SpringMenuRoute({required this.anchor, required this.items});

  final Rect anchor;
  final List<SpringMenuItem<T>> items;

  @override
  Color? get barrierColor => null;

  @override
  bool get barrierDismissible => true;

  @override
  String get barrierLabel => 'Close the menu';

  @override
  Duration get transitionDuration => const Duration(milliseconds: 380);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 150);

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    final c = context.colors;
    final screen = MediaQuery.sizeOf(context);
    return CustomSingleChildLayout(
      delegate: _BelowAnchor(anchor, MediaQuery.paddingOf(context)),
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: 220, maxWidth: screen.width - AppSpacing.l * 2),
        child: Material(
          color: c.background,
          elevation: 0,
          borderRadius: BorderRadius.circular(18),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(color: c.shade, offset: const Offset(0, 14), blurRadius: 34),
                BoxShadow(color: c.highlight, offset: const Offset(-2, -2), blurRadius: 6),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: IntrinsicWidth(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [for (final item in items) _Entry(item: item, onTap: () => Navigator.of(context).pop(item.value))],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: const Interval(0, 0.4)),
      child: ScaleTransition(
        scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack, reverseCurve: Curves.easeIn),
        alignment: Alignment.topRight,
        child: child,
      ),
    );
  }
}

/// Just under the anchor, right edges lined up, kept on screen.
class _BelowAnchor extends SingleChildLayoutDelegate {
  _BelowAnchor(this.anchor, this.padding);

  final Rect anchor;
  final EdgeInsets padding;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) => constraints.loosen();

  @override
  Offset getPositionForChild(Size size, Size child) {
    final left = (anchor.right - child.width).clamp(AppSpacing.s, size.width - child.width - AppSpacing.s);
    final top = (anchor.bottom + AppSpacing.xs).clamp(padding.top, size.height - child.height - padding.bottom);
    return Offset(left, top);
  }

  @override
  bool shouldRelayout(_BelowAnchor old) => old.anchor != anchor || old.padding != padding;
}

class _Entry extends StatelessWidget {
  const _Entry({required this.item, required this.onTap});

  final SpringMenuItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final colour = item.destructive ? c.bad : c.ink;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.small),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
          child: Row(
            children: [
              Icon(item.icon, size: 20, color: item.destructive ? c.bad : c.muted),
              const SizedBox(width: AppSpacing.m),
              Flexible(child: Text(item.label, style: TextStyle(color: colour, fontSize: 15, fontWeight: FontWeight.w600))),
            ],
          ),
        ),
      ),
    );
  }
}
