import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Press and hold a card: it swells a little and rises under the finger with
/// a light tick, gives a firmer tick if held on, and springs back when let go.
/// Once the firmer tick has come, letting go is not a tap.
///
/// It listens to the pointer without joining the gesture arena, so a scroll
/// starting under the finger still wins and simply springs the card back.
class HoldSwell extends StatefulWidget {
  const HoldSwell({super.key, required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  /// How long a press waits before the card swells, so a quick tap or the
  /// start of a scroll never makes it jump.
  static const swellAfter = Duration(milliseconds: 140);

  /// When the firmer tick comes, after the swell.
  static const holdAfter = Duration(milliseconds: 420);

  @override
  State<HoldSwell> createState() => _HoldSwellState();
}

class _HoldSwellState extends State<HoldSwell> with SingleTickerProviderStateMixin {
  late final _swell = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
    reverseDuration: const Duration(milliseconds: 380),
  );
  late final _curve = CurvedAnimation(parent: _swell, curve: Curves.easeOutBack, reverseCurve: Curves.easeOutBack.flipped);
  Timer? _swellTimer, _holdTimer;
  Offset? _down;
  bool _held = false;

  void _press(PointerDownEvent e) {
    _cancel();
    _down = e.position;
    _held = false;
    _swellTimer = Timer(HoldSwell.swellAfter, () {
      HapticFeedback.lightImpact();
      _swell.forward();
      _holdTimer = Timer(HoldSwell.holdAfter, () {
        _held = true;
        HapticFeedback.mediumImpact();
      });
    });
  }

  void _move(PointerMoveEvent e) {
    if (_down != null && (e.position - _down!).distance > kTouchSlop) _release();
  }

  void _cancel() {
    _swellTimer?.cancel();
    _holdTimer?.cancel();
  }

  void _release() {
    _cancel();
    _down = null;
    _swell.reverse();
  }

  @override
  void dispose() {
    _cancel();
    _curve.dispose();
    _swell.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Listener(
        onPointerDown: _press,
        onPointerMove: _move,
        onPointerUp: (_) => _release(),
        onPointerCancel: (_) => _release(),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap == null ? null : () => _held ? null : widget.onTap!(),
          child: AnimatedBuilder(
            animation: _curve,
            builder: (context, child) => Transform.translate(
              offset: Offset(0, -4 * _curve.value),
              child: Transform.scale(scale: 1 + 0.06 * _curve.value, child: child),
            ),
            child: widget.child,
          ),
        ),
      );
}
