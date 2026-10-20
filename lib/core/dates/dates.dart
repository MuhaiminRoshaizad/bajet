import 'package:intl/intl.dart';

/// User-facing dates are dd/mm/yyyy everywhere.
abstract final class Dates {
  static final _full = DateFormat('dd/MM/yyyy');
  static final _short = DateFormat('dd/MM');
  static final _weekday = DateFormat('EEE');
  static final _month = DateFormat('MMM');
  static final _monthYear = DateFormat('MMMM yyyy');
  static final _time = DateFormat('HH:mm');

  static String full(DateTime d) => _full.format(d);
  static String short(DateTime d) => _short.format(d);

  /// `Sat 09/01/2027`.
  static String dayFull(DateTime d) => '${weekday(d)} ${full(d)}';

  /// `Sun 25/10`.
  static String dayShort(DateTime d) => '${weekday(d)} ${short(d)}';

  /// `25/10 to 28/10/2026`, or the full first day when both are the same.
  static String span(DateTime first, DateTime last) {
    if (first == last) return full(first);
    return '${first.year == last.year ? short(first) : full(first)} to ${full(last)}';
  }

  /// `Wed`.
  static String weekday(DateTime d) => _weekday.format(d);

  /// `Nov`.
  static String monthShort(DateTime d) => _month.format(d);

  /// `October 2026`.
  static String monthYear(DateTime d) => _monthYear.format(d);

  /// `14:05`, on the 24-hour clock.
  static String time(DateTime d) => _time.format(d);
}
