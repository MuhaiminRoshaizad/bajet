import 'package:bajet/core/widgets/money_keypad.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('keys fill the amount from the right, like a till', () {
    var sen = 0;
    for (final k in ['1', '5', '0']) {
      sen = pressMoneyKey(sen, k, maxSen: 100000000);
    }
    expect(sen, 150);
    expect(pressMoneyKey(sen, '00', maxSen: 100000000), 15000);
    expect(pressMoneyKey(sen, 'del', maxSen: 100000000), 15);
    expect(pressMoneyKey(0, '0', maxSen: 100000000), 0);
  });

  test('a key that would pass the limit is ignored', () {
    expect(pressMoneyKey(99999, '9', maxSen: 100000), 99999);
    expect(pressMoneyKey(1001, '00', maxSen: 100000), 1001);
    expect(pressMoneyKey(1000, '00', maxSen: 100000), 100000);
  });
}
