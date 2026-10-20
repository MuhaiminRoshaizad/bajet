import 'package:bajet/core/dates/dates.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a span of days reads as dd/mm to dd/mm/yyyy, with the year once', () {
    expect(Dates.span(DateTime.utc(2026, 10, 25), DateTime.utc(2026, 10, 28)), '25/10 to 28/10/2026');
    expect(Dates.span(DateTime.utc(2026, 12, 30), DateTime.utc(2027, 1, 2)), '30/12/2026 to 02/01/2027');
    expect(Dates.span(DateTime.utc(2026, 10, 25), DateTime.utc(2026, 10, 25)), '25/10/2026');
  });

  test('a time is on the 24-hour clock', () {
    expect(Dates.time(DateTime(2026, 10, 20, 14, 5)), '14:05');
    expect(Dates.time(DateTime(2026, 10, 20, 9, 30)), '09:30');
  });

  test('a day can lead with its weekday', () {
    expect(Dates.dayFull(DateTime.utc(2027, 1, 9)), 'Sat 09/01/2027');
    expect(Dates.dayShort(DateTime.utc(2026, 10, 25)), 'Sun 25/10');
  });
}
