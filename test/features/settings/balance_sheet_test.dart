import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/app_harness.dart';

void main() {
  Future<void> openBalance(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Balance'));
  }

  testWidgets('Settings → Balance offers to match the bank', (tester) async {
    await pumpApp(tester);
    await openBalance(tester);
    await tester.pumpAndSettle();
    expect(find.text('Your balance'), findsOneWidget);
    expect(find.text('bajet has RM1,500.00 from your entries.'), findsOneWidget);

    await tester.tap(find.text('Match what you really have'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextFormField, 'Bank app says'), findsOneWidget);
  });

  testWidgets('the starting balance can be fixed, moving every figure since', (tester) async {
    final world = await pumpApp(tester);
    await openBalance(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fix the starting balance instead'));
    await tester.pumpAndSettle();
    expect(find.text('1,500.00'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextFormField, 'Balance on 01/07/2026'), '160000');
    await tester.tap(find.text('Save starting balance'));
    await tester.pumpAndSettle();

    expect(world.settings!.openingBalance, 160000);
    expect(world.entries, isEmpty);
    expect(find.text('RM1,600.00'), findsWidgets);
  });
}
