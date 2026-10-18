import 'dart:ui' show lerpDouble;

import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';

import '../theme/app_motion.dart';

/// Something arriving, such as a new message: it springs up from below at
/// just over half its size, growing out of [alignment], passing its size by
/// a little and settling. Without [animate], or with the system's
/// reduce-motion setting on, it is simply there.
class SpringIn extends StatefulWidget {
  const SpringIn({super.key, required this.animate, required this.alignment, required this.child});

  final bool animate;
  final Alignment alignment;
  final Widget child;

  @override
  State<SpringIn> createState() => _SpringInState();
}

class _SpringInState extends State<SpringIn> with SingleTickerProviderStateMixin {
  late final _t = AnimationController.unbounded(vsync: this, value: 1);

  @override
  void initState() {
    super.initState();
    if (widget.animate) {
      _t.value = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
          _t.value = 1;
        } else {
          _t.animateWith(SpringSimulation(AppMotion.spring, 0, 1, 0, snapToEnd: true));
        }
      });
    }
  }

  @override
  void dispose() {
    _t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _t,
        child: widget.child,
        builder: (context, child) {
          final t = _t.value;
          return Opacity(
            opacity: (t * 2).clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(0, 24 * (1 - t)),
              child: Transform.scale(scale: lerpDouble(0.55, 1, t), alignment: widget.alignment, child: child),
            ),
          );
        },
      );
}
