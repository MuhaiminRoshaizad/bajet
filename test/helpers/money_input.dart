import 'package:bajet/core/widgets/money_keypad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Types [digits] into a money field the way the owner does: tap it, clear
/// what is there, press the keypad keys, then Done. Empty [digits] clears it.
Future<void> enterAmount(WidgetTester tester, Finder field, String digits) async {
  await tester.ensureVisible(field);
  await tester.tap(field);
  await tester.pumpAndSettle();
  if (find.text('Clear').evaluate().isNotEmpty) {
    await tester.tap(find.text('Clear'));
    await tester.pump();
  }
  for (final k in digits.split('')) {
    await tester.tap(find.descendant(of: find.byType(MoneyKeypad), matching: find.text(k)).last);
    await tester.pump();
  }
  await tester.tap(find.widgetWithText(FilledButton, 'Done'));
  await tester.pumpAndSettle();
}
