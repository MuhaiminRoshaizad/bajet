import 'package:bajet/core/money/money.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Money.format', () {
    test('uses RM with no space, two decimals and a thousands separator', () {
      expect(Money.format(125000), 'RM1,250.00');
      expect(Money.format(150), 'RM1.50');
      expect(Money.format(0), 'RM0.00');
      expect(Money.format(249900), 'RM2,499.00');
    });

    test('marks negatives with a minus sign before RM', () {
      expect(Money.format(-800), '−RM8.00');
    });
  });

  group('Money.formatWhole', () {
    test('drops sen', () {
      expect(Money.formatWhole(3000), 'RM30');
      expect(Money.formatWhole(100000), 'RM1,000');
    });
  });
}
