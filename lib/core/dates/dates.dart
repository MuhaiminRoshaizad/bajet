import 'package:intl/intl.dart';

/// User-facing dates are dd/mm/yyyy everywhere.
abstract final class Dates {
  static final _full = DateFormat('dd/MM/yyyy');
  static final _short = DateFormat('dd/MM');
  static final _weekday = DateFormat('EEE');
  static final _month = DateFormat('MMM');

  static String full(DateTime d) => _full.format(d);
  static String short(DateTime d) => _short.format(d);

  /// `Wed`.
  static String weekday(DateTime d) => _weekday.format(d);

  /// `Nov`.
  static String monthShort(DateTime d) => _month.format(d);
}
