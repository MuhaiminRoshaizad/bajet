import 'package:intl/intl.dart';

/// Money is held as integer sen everywhere; these are the only places it
/// turns into text.
abstract final class Money {
  // The CLDR Malay pattern is ¤#,##0.00, which gives RM1,250.00 with no space.
  static final _withSen = NumberFormat.currency(locale: 'ms', symbol: 'RM', decimalDigits: 2);
  static final _whole = NumberFormat.currency(locale: 'ms', symbol: 'RM', decimalDigits: 0);

  /// `125000` → `RM1,250.00`; negatives use a true minus sign.
  static String format(int sen) => _sign(sen) + _withSen.format(sen.abs() / 100);

  /// `125000` → `RM1,250`. Callers use this only for whole-ringgit figures.
  static String formatWhole(int sen) => _sign(sen) + _whole.format((sen.abs() / 100).round());

  static String _sign(int sen) => sen < 0 ? '−' : '';
}
