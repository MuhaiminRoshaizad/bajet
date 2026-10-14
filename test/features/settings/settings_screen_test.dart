import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/app_harness.dart';

Future<void> openSettings(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Settings'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('settings opens from Today and shows the allowance', (tester) async {
    await pumpApp(tester);
    await openSettings(tester);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('RM50 a week'), findsOneWidget);
  });

  testWidgets('changing the allowance and buffer saves both', (tester) async {
    final world = await pumpApp(tester);
    await openSettings(tester);
    await tester.tap(find.text('Weekly allowance and buffer'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'Weekly allowance'), '7500');
    await tester.enterText(find.widgetWithText(TextFormField, 'Keep at least (optional)'), '');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect((world.settings!.weeklyCap, world.settings!.buffer), (7500, 0));
    expect(world.settings!.openingBalance, demoSettings.openingBalance);
    expect(find.text('RM75 a week'), findsOneWidget);
  });

  testWidgets('an empty allowance is refused', (tester) async {
    final world = await pumpApp(tester);
    await openSettings(tester);
    await tester.tap(find.text('Weekly allowance and buffer'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'Weekly allowance'), '');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(find.text('Enter how much you allow each week'), findsOneWidget);
    expect(world.settings!.weeklyCap, demoSettings.weeklyCap);
  });
}
