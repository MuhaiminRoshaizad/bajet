/// The 4 pt spacing scale. Widgets use these, never raw padding numbers.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double s = 8;
  static const double m = 12;
  static const double l = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
}

abstract final class AppRadii {
  static const double small = 12;
  static const double control = 16;
  static const double card = 24;
  static const double sheet = 30;
  static const double pill = 999;
}

/// How far a soft surface stands out from, or sinks into, the background:
/// the offset of its light and dark edges in logical pixels. The blur is
/// twice the offset.
abstract final class AppDepth {
  static const double card = 6;
  static const double control = 3;
  static const double well = 3;
}
