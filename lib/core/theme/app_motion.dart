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
}
