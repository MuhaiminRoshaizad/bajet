import 'package:flutter/widgets.dart';

/// Where the coaches on a screen look for a moment, on top of their mood,
/// and a wobble to give them: what makes them notice the user scrolling or
/// typing. One is shared by every face it is handed to.
class CoachAttention extends ChangeNotifier {
  Offset _look = Offset.zero;
  double _nudge = 0;
  int _nudges = 0;

  /// How far the eyes turn, in the person's 100-unit face; the orb's face
  /// is twice the size and turns twice as far.
  Offset get look => _look;

  /// How far the latest wobble squashes the face, 0 to 1.
  double get nudge => _nudge;

  /// Counts wobbles, so a face can tell a new one from one it has had.
  int get nudges => _nudges;

  void lookAt(Offset to) {
    if (to == _look) return;
    _look = to;
    notifyListeners();
  }

  void wobble(double amount) {
    _nudge = amount.clamp(0, 1);
    _nudges++;
    notifyListeners();
  }
}

/// Turns the scrolling of [child] into [attention]: the faces look the way
/// the page is moving, harder the faster it goes, then back ahead once it
/// stops, wobbling once if it was flung.
class ScrollAttention extends StatefulWidget {
  const ScrollAttention({super.key, required this.attention, required this.child, this.reach = 2.2});

  final CoachAttention attention;

  /// How far the eyes turn at full speed.
  final double reach;
  final Widget child;

  /// A speed, in logical pixels a second, that turns the eyes all the way
  /// and counts as a fling.
  static const fast = 900.0;

  @override
  State<ScrollAttention> createState() => _ScrollAttentionState();
}

class _ScrollAttentionState extends State<ScrollAttention> {
  final _clock = Stopwatch()..start();
  var _last = Duration.zero;
  var _peak = 0.0;

  bool _onScroll(ScrollNotification n) {
    if (n is ScrollUpdateNotification && n.scrollDelta != null) {
      final now = _clock.elapsed;
      final ms = (now - _last).inMicroseconds / 1000;
      _last = now;
      // A first update after a pause has no speed to speak of yet.
      if (ms <= 0 || ms > 100) return false;
      // Read as it moves on screen, whichever end the list is laid out from.
      final speed = n.scrollDelta! / ms * 1000 * (n.metrics.axisDirection == AxisDirection.up ? -1 : 1);
      if (speed.abs() > _peak) _peak = speed.abs();
      widget.attention.lookAt(Offset(0, (speed / ScrollAttention.fast).clamp(-1.0, 1.0) * widget.reach));
    } else if (n is ScrollEndNotification) {
      widget.attention.lookAt(Offset.zero);
      if (_peak > ScrollAttention.fast) widget.attention.wobble((_peak / 5000).clamp(0.1, 0.45));
      _peak = 0;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) => NotificationListener<ScrollNotification>(onNotification: _onScroll, child: widget.child);
}
