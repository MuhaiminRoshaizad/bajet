import 'package:flutter/animation.dart';

/// One motion language for the whole app: a soft ease-out, short durations.
abstract final class AppMotion {
  static const Curve ease = Curves.easeOutQuint;
  static const Duration press = Duration(milliseconds: 120);
  static const Duration fast = Duration(milliseconds: 250);
  static const Duration enter = Duration(milliseconds: 480);

  /// Delay between consecutive cards as a screen rises into place.
  static const Duration stagger = Duration(milliseconds: 55);

  /// How far a card travels upward on entry, in logical pixels.
  static const double rise = 18;

  /// The bounce for a shape settling on a new value: it passes the value by
  /// about a tenth and settles in under a second. Figures in words never use
  /// it, since a number that overshoots reads wrong for a moment.
  static final spring = SpringDescription.withDampingRatio(mass: 1, stiffness: 180, ratio: 0.6);
}
