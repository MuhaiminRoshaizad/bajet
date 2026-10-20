import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_spacing.dart';

/// The two shadows of a surface raised [depth] pixels toward a light at the
/// top left: a lit edge up and left, a shadowed edge down and right.
List<BoxShadow> softShadows(AppColors c, double depth) => [
      BoxShadow(color: c.highlight, offset: Offset(-depth, -depth), blurRadius: depth * 2),
      BoxShadow(color: c.shade, offset: Offset(depth, depth), blurRadius: depth * 2),
    ];

/// The shadows of a surface floating over the page rather than moulded
/// from it, such as the bottom bar the page scrolls under: the same lit
/// edge, with a longer, softer shadow dropped below.
List<BoxShadow> floatingShadows(AppColors c) => [
      BoxShadow(color: c.highlight, offset: const Offset(-5, -5), blurRadius: 12),
      BoxShadow(color: c.shade, offset: const Offset(6, 9), blurRadius: 20),
    ];

/// A round button filled with the primary blue and moulded by the page's
/// top-left light (AppColors.primaryLit to primaryDeep), for the one action
/// that matters most wherever it sits. It sinks a little while pressed and
/// springs back.
class MouldedButton extends StatefulWidget {
  const MouldedButton({super.key, required this.size, required this.onTap, required this.semanticLabel, required this.child});

  final double size;
  final VoidCallback onTap;
  final String semanticLabel;
  final Widget child;

  @override
  State<MouldedButton> createState() => _MouldedButtonState();
}

class _MouldedButtonState extends State<MouldedButton> {
  bool _pressed = false;
  bool _focused = false;

  void _press(bool down) {
    if (down != _pressed) setState(() => _pressed = down);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      excludeSemantics: true,
      onTap: widget.onTap,
      child: FocusableActionDetector(
        onShowFocusHighlight: (v) => setState(() => _focused = v),
        actions: {ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) => widget.onTap())},
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => _press(true),
          onTapUp: (_) => _press(false),
          onTapCancel: () => _press(false),
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: _pressed ? 0.88 : 1,
            duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 380),
            curve: Curves.easeOutBack,
            child: Container(
              width: widget.size,
              height: widget.size,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                // 145°, top left to bottom right, as the light falls.
                gradient: LinearGradient(
                  begin: const Alignment(-0.57, -0.82),
                  end: const Alignment(0.57, 0.82),
                  colors: [c.primaryLit, c.primary, c.primaryDeep],
                  stops: const [0, 0.48, 1],
                ),
                boxShadow: c.mouldShadows,
              ),
              foregroundDecoration: _focused ? BoxDecoration(shape: BoxShape.circle, border: Border.all(color: c.ink, width: 3)) : null,
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

/// A card moulded out of the background: same colour, told apart only by its
/// soft edges. Content inside it carries its own contrast, so the edges are
/// never the only thing that says what is there.
class SoftCard extends StatelessWidget {
  const SoftCard({super.key, required this.child, this.padding = const EdgeInsets.all(AppSpacing.l + 2), this.radius = AppRadii.card});

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: c.background,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: softShadows(c, AppDepth.card),
      ),
      child: child,
    );
  }
}

/// An area pressed into the surface, for notices, readouts and tracks. With
/// [circle] it is round and sized by its parent.
class SoftWell extends StatelessWidget {
  const SoftWell({super.key, this.child, this.padding = const EdgeInsets.all(AppSpacing.l), this.radius = AppRadii.control, this.circle = false});

  final Widget? child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final bool circle;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return CustomPaint(
      painter: _WellPainter(c, radius: radius, circle: circle),
      child: Padding(padding: padding, child: child),
    );
  }
}

class _WellPainter extends CustomPainter {
  _WellPainter(this.c, {required this.radius, required this.circle});

  final AppColors c;
  final double radius;
  final bool circle;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final shape = RRect.fromRectAndRadius(rect, Radius.circular(circle ? size.shortestSide / 2 : radius));
    const d = AppDepth.well;
    canvas
      ..save()
      ..clipRRect(shape)
      ..drawRRect(shape, Paint()..color = c.well);
    // Flutter has no inner shadow, so each edge is the blurred outline of
    // everything outside the shape, nudged inward and clipped to it.
    final outside = Path.combine(PathOperation.difference, Path()..addRect(rect.inflate(d * 4)), Path()..addRRect(shape));
    for (final (color, offset) in [(c.shade, const Offset(d, d)), (c.highlight, const Offset(-d, -d))]) {
      canvas.drawPath(outside.shift(offset), Paint()..color = color..maskFilter = const MaskFilter.blur(BlurStyle.normal, d));
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_WellPainter old) => old.c != c || old.radius != radius || old.circle != circle;
}

/// A raised control that sinks flat while pressed. When [selected] it sits in
/// a well with an accent outline: the outline, not the depth, carries the
/// state, because a shadow alone falls short of the 3:1 WCAG asks of it.
class SoftButton extends StatefulWidget {
  const SoftButton({
    super.key,
    required this.child,
    required this.onTap,
    this.selected = false,
    this.radius = AppRadii.control,
    this.padding = EdgeInsets.zero,
    this.color,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onTap;
  final bool selected;
  final double radius;
  final EdgeInsetsGeometry padding;

  /// A fill for the one accent control on a screen, such as the + button.
  final Color? color;
  final String? semanticLabel;

  @override
  State<SoftButton> createState() => _SoftButtonState();
}

class _SoftButtonState extends State<SoftButton> {
  bool _pressed = false;
  bool _focused = false;

  void _press(bool down) {
    if (widget.onTap != null && down != _pressed) setState(() => _pressed = down);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final shape = BorderRadius.circular(widget.radius);
    final animate = !MediaQuery.disableAnimationsOf(context);
    final Widget face = widget.selected
        ? Stack(
            fit: StackFit.passthrough,
            children: [
              Positioned.fill(child: SoftWell(radius: widget.radius, padding: EdgeInsets.zero)),
              Container(
                padding: widget.padding,
                decoration: BoxDecoration(borderRadius: shape, border: Border.all(color: c.primary, width: 2)),
                child: widget.child,
              ),
            ],
          )
        : AnimatedContainer(
            duration: animate ? AppMotion.press : Duration.zero,
            curve: AppMotion.ease,
            padding: widget.padding,
            decoration: BoxDecoration(
              color: widget.color ?? c.background,
              borderRadius: shape,
              boxShadow: softShadows(c, _pressed ? 0.5 : AppDepth.control),
            ),
            child: widget.child,
          );
    return Semantics(
      button: true,
      selected: widget.selected,
      label: widget.semanticLabel,
      excludeSemantics: widget.semanticLabel != null,
      onTap: widget.onTap,
      child: FocusableActionDetector(
        enabled: widget.onTap != null,
        onShowFocusHighlight: (v) => setState(() => _focused = v),
        actions: {ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) => widget.onTap?.call())},
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => _press(true),
          onTapUp: (_) => _press(false),
          onTapCancel: () => _press(false),
          onTap: widget.onTap,
          child: DecoratedBox(
            position: DecorationPosition.foreground,
            decoration: BoxDecoration(
              borderRadius: shape,
              border: _focused ? Border.all(color: c.primary, width: 3) : null,
            ),
            child: face,
          ),
        ),
      ),
    );
  }
}

/// A progress track pressed into the surface, filled from the left in
/// [color].
class SoftMeter extends StatelessWidget {
  const SoftMeter({super.key, required this.value, required this.color, this.height = 12});

  final double value;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: height,
        child: SoftWell(
          radius: AppRadii.pill,
          padding: const EdgeInsets.all(2),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: value.clamp(0.0, 1.0),
              heightFactor: 1,
              child: DecoratedBox(decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(AppRadii.pill))),
            ),
          ),
        ),
      );
}
