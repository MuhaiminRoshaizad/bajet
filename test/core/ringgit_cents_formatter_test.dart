import 'package:bajet/core/validation/ringgit_cents_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

String type(String sequence) {
  const f = RinggitCentsFormatter();
  var value = TextEditingValue.empty;
  for (final ch in sequence.split('')) {
    value = f.formatEditUpdate(value, TextEditingValue(text: value.text + ch));
  }
  return value.text;
}

void main() {
  test('digits fill in from the right', () {
    expect(type('1'), '0.01');
    expect(type('150'), '1.50');
    expect(type('32000'), '320.00');
  });

  test('groups thousands', () {
    expect(type('125000'), '1,250.00');
    expect(type('10000000'), '100,000.00');
  });

  test('ignores anything that is not a digit', () {
    expect(type('1a.5-0'), '1.50');
  });

  test('backspace shifts the amount right', () {
    const f = RinggitCentsFormatter();
    final next = f.formatEditUpdate(const TextEditingValue(text: '1.50'), const TextEditingValue(text: '1.5'));
    expect(next.text, '0.15');
  });

  test('zero clears the field', () {
    expect(type('0'), '');
    expect(type('00'), '');
  });

  test('caps at the maximum', () {
    expect(type('9999999999'), '1,000,000.00');
  });

  test('parse reads sen back from field text', () {
    expect(RinggitCentsFormatter.parse('1,250.00'), 125000);
    expect(RinggitCentsFormatter.parse(''), 0);
  });
}
