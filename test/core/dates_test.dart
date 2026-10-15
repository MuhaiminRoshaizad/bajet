import 'package:bajet/core/dates/dates.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a span of days reads as dd/mm to dd/mm/yyyy, with the year once', () {
    expect(Dates.span(DateTime.utc(2026, 10, 25), DateTime.utc(2026, 10, 28)), '25/10 to 28/10/2026');
    expect(Dates.span(DateTime.utc(2026, 12, 30), DateTime.utc(2027, 1, 2)), '30/12/2026 to 02/01/2027');
    expect(Dates.span(DateTime.utc(2026, 10, 25), DateTime.utc(2026, 10, 25)), '25/10/2026');
  });
}
