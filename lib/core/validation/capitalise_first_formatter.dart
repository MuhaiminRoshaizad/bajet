import 'package:flutter/services.dart';

/// Starts a name or note with a capital, `makan` reading `Makan`. Fields
/// also ask the keyboard for sentence capitals, but that is only a hint: some
/// keyboards ignore it, and a `DropdownMenu` cannot ask at all.
class CapitaliseFirstFormatter extends TextInputFormatter {
  const CapitaliseFirstFormatter();

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text;
    if (text.isEmpty) return newValue;
    final first = text[0], upper = first.toUpperCase();
    // A letter that grows when capitalised, such as ß, is left alone so the
    // cursor stays where it was.
    if (upper == first || upper.length != 1) return newValue;
    return newValue.copyWith(text: upper + text.substring(1));
  }
}
