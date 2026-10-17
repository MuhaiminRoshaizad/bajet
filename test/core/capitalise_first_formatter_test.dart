import 'package:bajet/core/validation/capitalise_first_formatter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

String type(String sequence) {
  const f = CapitaliseFirstFormatter();
  var value = TextEditingValue.empty;
  for (final ch in sequence.split('')) {
    final typed = value.text + ch;
    value = f.formatEditUpdate(value, TextEditingValue(text: typed, selection: TextSelection.collapsed(offset: typed.length)));
  }
  return value.text;
}

void main() {
  test('the first letter becomes a capital, and nothing else changes', () {
    expect(type('makan'), 'Makan');
    expect(type('maybank2u'), 'Maybank2u');
    expect(type('lunch with team'), 'Lunch with team');
    expect(type('Already'), 'Already');
  });

  test('text that does not start with a letter is left as it is', () {
    expect(type('7-eleven'), '7-eleven');
    expect(type(' makan'), ' makan');
  });

  test('the cursor stays where it was', () {
    const f = CapitaliseFirstFormatter();
    final out = f.formatEditUpdate(TextEditingValue.empty, const TextEditingValue(text: 'mak', selection: TextSelection.collapsed(offset: 2)));
    expect(out.text, 'Mak');
    expect(out.selection, const TextSelection.collapsed(offset: 2));
  });
}
