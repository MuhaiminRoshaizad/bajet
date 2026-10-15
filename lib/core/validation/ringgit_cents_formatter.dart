import 'package:flutter/services.dart';

/// Cashier-style money entry: digits fill in from the right against a fixed
/// two-decimal fraction, so `1`, `5`, `0` reads `1.50` and the field can never
/// hold a malformed amount. Thousands are grouped as they grow (`1,250.00`).
class RinggitCentsFormatter extends TextInputFormatter {
  const RinggitCentsFormatter({this.maxSen = 100000000, this.prefix = ''}); // RM1,000,000.00

  final int maxSen;

  /// Written in front of the amount, such as `RM`, for a field that shows
  /// the currency as part of its text; [parse] ignores it.
  final String prefix;

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 12) digits = digits.substring(0, 12);
    var sen = int.tryParse(digits) ?? 0;
    if (sen <= 0) return const TextEditingValue();
    if (sen > maxSen) sen = maxSen;
    final text = '$prefix${format(sen)}';
    return TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
  }

  /// `125000` → `1,250.00`, the field's text for an amount in sen.
  static String format(int sen) {
    final whole = (sen ~/ 100).toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
    return '$whole.${(sen % 100).toString().padLeft(2, '0')}';
  }

  /// The amount in sen held by a field's text, or 0 when it is empty.
  static int parse(String text) => int.tryParse(text.replaceAll(RegExp(r'\D'), '')) ?? 0;
}
