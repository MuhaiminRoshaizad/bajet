import 'package:bajet/features/plan/domain/plan_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a weekly amount spreads over seven days and adds back up exactly', () {
    expect(spreadOverWeek(3500), [500, 500, 500, 500, 500, 500, 500]);
    expect(spreadOverWeek(3000), [429, 429, 429, 429, 428, 428, 428]);
    expect(spreadOverWeek(3000).reduce((a, b) => a + b), 3000);
    expect(spreadOverWeek(0), List.filled(7, 0));
  });
}
