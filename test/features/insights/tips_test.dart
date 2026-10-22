import 'package:bajet/features/insights/domain/tips.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a tip lasts Monday to Sunday and the next Monday brings the next', () {
    final monday = DateTime.utc(2026, 10, 19);
    final week = [for (var i = 0; i < 7; i++) tipFor(DateTime.utc(2026, 10, 19 + i))];
    expect(week.toSet(), {tipFor(monday)});
    final next = tipFor(DateTime.utc(2026, 10, 26));
    expect(tips.indexOf(next), (tips.indexOf(week.first) + 1) % tips.length);
  });
}
