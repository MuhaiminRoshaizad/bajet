import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Press and hold a card: it swells a little and rises under the finger with
/// a light tick, gives a firmer tick if held on, and springs back when let go.
/// Once the firmer tick has come, letting go is not a tap.
///
/// The swell listens to the pointer without joining the gesture arena, so a
/// scroll starting under the finger still wins and simply springs the card
/// back. The firmer tick is a long press: it wins the finger from the scroll,
/// so with [onPickUp] the card is picked up there and [onDrag] follows the
/// finger until [onDrop].
class HoldSwell extends StatefulWidget {
  const HoldSwell({super.key, required this.child, this.onTap, this.onPickUp, this.onDrag, this.onDrop});

  final Widget child;
  final VoidCallback? onTap;

  /// Called with the firmer tick; the card then lifts a little higher.
  final VoidCallback? onPickUp;

  /// How far the finger has moved since the card was picked up.
  final ValueChanged<Offset>? onDrag;
  final VoidCallback? onDrop;

  /// How long a press waits before the card swells, so a quick tap or the
  /// start of a scroll never makes it jump.
  static const swellAfter = Duration(milliseconds: 140);

  /// When the firmer tick comes, after the swell.
  static const holdAfter = Duration(milliseconds: 420);

  @override
  State<HoldSwell> createState() => _HoldSwellState();
}

class _HoldSwellState extends State<HoldSwell> with TickerProviderStateMixin {
  late final _swell = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
    reverseDuration: const Duration(milliseconds: 380),
  );
  late final _curve = CurvedAnimation(parent: _swell, curve: Curves.easeOutBack, reverseCurve: Curves.easeOutBack.flipped);

  /// The extra lift of a card picked up.
  late final _lift = AnimationController(vsync: this, duration: const Duration(milliseconds: 220), reverseDuration: const Duration(milliseconds: 380));
  Timer? _swellTimer;
  Offset? _down;
  bool _picked = false;

  void _press(PointerDownEvent e) {
    _swellTimer?.cancel();
    _down = e.position;
    _swellTimer = Timer(HoldSwell.swellAfter, () {
      HapticFeedback.lightImpact();
      _swell.forward();
    });
  }

  void _move(PointerMoveEvent e) {
    // Picked up, the card follows the finger instead of settling.
    if (!_picked && _down != null && (e.position - _down!).distance > kTouchSlop) _release();
  }

  void _release() {
    _swellTimer?.cancel();
    _down = null;
    _swell.reverse();
  }

  void _held() {
    HapticFeedback.mediumImpact();
    if (widget.onPickUp == null) return;
    _picked = true;
    _lift.forward();
    widget.onPickUp!();
  }

  void _letGo() {
    if (!_picked) return;
    _picked = false;
    _lift.reverse();
    _release();
    widget.onDrop?.call();
  }

  @override
  void dispose() {
    _swellTimer?.cancel();
    _curve.dispose();
    _swell.dispose();
    _lift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Listener(
        onPointerDown: _press,
        onPointerMove: _move,
        onPointerUp: (_) => _release(),
        onPointerCancel: (_) => _release(),
        child: RawGestureDetector(
          behavior: HitTestBehavior.opaque,
          gestures: {
            if (widget.onTap != null)
              TapGestureRecognizer: GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
                TapGestureRecognizer.new,
                (r) => r.onTap = widget.onTap,
              ),
            LongPressGestureRecognizer: GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
              () => LongPressGestureRecognizer(duration: HoldSwell.swellAfter + HoldSwell.holdAfter),
              (r) => r
                ..onLongPressStart = ((_) => _held())
                ..onLongPressMoveUpdate = ((d) => _picked ? widget.onDrag?.call(d.offsetFromOrigin) : null)
                ..onLongPressEnd = ((_) => _letGo())
                ..onLongPressCancel = _letGo,
            ),
          },
          child: AnimatedBuilder(
            animation: Listenable.merge([_curve, _lift]),
            builder: (context, child) => Transform.translate(
              offset: Offset(0, -4 * _curve.value - 2 * _lift.value),
              child: Transform.scale(scale: 1 + 0.06 * _curve.value + 0.02 * _lift.value, child: child),
            ),
            child: widget.child,
          ),
        ),
      );
}
