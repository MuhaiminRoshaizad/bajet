import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// One choice in a [SpringMenuButton]'s menu.
class SpringMenuItem<T> {
  const SpringMenuItem({required this.value, required this.icon, required this.label, this.destructive = false});

  final T value;
  final IconData icon;
  final String label;

  /// Shown in the warning colour below a line, for a choice that removes
  /// something.
  final bool destructive;
}

/// The ⋮ in a screen's header. The button itself opens into its menu: a
/// card a step lighter than the page grows out of it, passing its size a
/// little before it settles, while the screen dims and the rows spring in
/// one after another. A tap outside folds it back into the button, without
/// a bounce. With the system's reduce-motion setting on it simply appears.
class SpringMenuButton<T> extends StatelessWidget {
  const SpringMenuButton({super.key, required this.items, required this.onSelected, this.title, this.tooltip = 'More'});

  final List<SpringMenuItem<T>> items;
  final ValueChanged<T> onSelected;

  /// What the menu acts on, named in its corner.
  final String? title;
  final String tooltip;

  Future<void> _open(BuildContext context) async {
    final box = context.findRenderObject()! as RenderBox;
    final anchor = box.localToGlobal(Offset.zero) & box.size;
    final picked = await Navigator.of(context).push<T>(_SpringMenuRoute<T>(anchor: anchor, items: items, title: title));
    if (picked != null) onSelected(picked);
  }

  @override
  Widget build(BuildContext context) => Builder(
        builder: (context) => IconButton(onPressed: () => _open(context), icon: const Icon(Icons.more_vert_rounded), tooltip: tooltip),
      );
}

class _SpringMenuRoute<T> extends PopupRoute<T> {
  _SpringMenuRoute({required this.anchor, required this.items, required this.title});

  final Rect anchor;
  final List<SpringMenuItem<T>> items;
  final String? title;

  @override
  Color? get barrierColor => Colors.black.withValues(alpha: 0.3);

  @override
  bool get barrierDismissible => true;

  @override
  String get barrierLabel => 'Close the menu';

  @override
  Duration get transitionDuration => const Duration(milliseconds: 460);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 220);

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    final c = context.colors;
    final still = MediaQuery.disableAnimationsOf(context);
    final grow = still ? kAlwaysCompleteAnimation : CurvedAnimation(parent: animation, curve: Curves.easeOutBack, reverseCurve: Curves.easeInCubic);
    final rows = <Widget>[];
    for (final (i, item) in items.indexed) {
      if (item.destructive && i > 0) rows.add(Divider(height: AppSpacing.s + 1, indent: AppSpacing.m, endIndent: AppSpacing.m, color: c.line));
      rows.add(_Rise(
        animation: still ? kAlwaysCompleteAnimation : animation,
        start: 0.12 + 0.08 * i,
        child: _Entry(item: item, onTap: () => Navigator.of(context).pop(item.value)),
      ));
    }
    final screen = MediaQuery.sizeOf(context);
    return CustomSingleChildLayout(
      delegate: _OverAnchor(anchor, MediaQuery.paddingOf(context)),
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: 220, maxWidth: screen.width - AppSpacing.l * 2),
        child: AnimatedBuilder(
          animation: grow,
          builder: (context, child) => PhysicalShape(
            key: const ValueKey('spring-menu-card'),
            clipper: _Morph(grow.value, anchor.size),
            color: c.raised,
            elevation: 10,
            shadowColor: c.shade,
            child: child,
          ),
          child: Material(
            type: MaterialType.transparency,
            child: IntrinsicWidth(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // The button's own place in the corner, so the ⋮ stays put
                  // while the card grows out of it.
                  Row(
                    children: [
                      if (title != null)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(left: AppSpacing.l),
                            child: Text(
                              title!.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: c.muted, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.8),
                            ),
                          ),
                        )
                      else
                        const Spacer(),
                      SizedBox.fromSize(
                        size: anchor.size,
                        child: Center(
                          child: RotationTransition(
                            turns: Tween(begin: 0.0, end: 0.25).animate(grow),
                            child: Icon(Icons.more_vert_rounded, color: c.ink),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(padding: const EdgeInsets.fromLTRB(6, 0, 6, 6), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: rows)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // The card grows itself in buildPage, so the route adds nothing on top.
  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) => child;
}

/// The card's outline at [t]: the button's circle in the top right corner
/// at 0, the whole card at 1, and past it while the spring overshoots.
class _Morph extends CustomClipper<Path> {
  _Morph(this.t, this.button);

  final double t;
  final Size button;

  @override
  Path getClip(Size size) {
    final from = Rect.fromLTWH(size.width - button.width, 0, button.width, button.height);
    final rect = Rect.lerp(from, Offset.zero & size, t)!;
    final radius = button.shortestSide / 2 + (22 - button.shortestSide / 2) * t.clamp(0.0, 1.0);
    return Path()..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));
  }

  @override
  bool shouldReclip(_Morph old) => old.t != t || old.button != button;
}

/// A row fading and springing down into place, starting a little after the
/// one above it.
class _Rise extends StatelessWidget {
  const _Rise({required this.animation, required this.start, required this.child});

  final Animation<double> animation;
  final double start;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final from = start.clamp(0.0, 0.6);
    return FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Interval(from, from + 0.3)),
      child: SlideTransition(
        position: Tween(begin: const Offset(0, -0.25), end: Offset.zero).animate(CurvedAnimation(parent: animation, curve: Interval(from, from + 0.4, curve: Curves.easeOutBack))),
        child: child,
      ),
    );
  }
}

/// Over the anchor, top right corners lined up, kept on screen.
class _OverAnchor extends SingleChildLayoutDelegate {
  _OverAnchor(this.anchor, this.padding);

  final Rect anchor;
  final EdgeInsets padding;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) => constraints.loosen();

  @override
  Offset getPositionForChild(Size size, Size child) {
    final left = (anchor.right - child.width).clamp(AppSpacing.s, size.width - child.width);
    final top = anchor.top.clamp(padding.top, size.height - child.height - padding.bottom);
    return Offset(left, top);
  }

  @override
  bool shouldRelayout(_OverAnchor old) => old.anchor != anchor || old.padding != padding;
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
