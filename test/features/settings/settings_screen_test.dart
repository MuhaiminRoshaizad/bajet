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
    expect(find.text('RM50 a week · keep RM500'), findsOneWidget);
    expect(find.text('Your plan'), findsOneWidget);
  });

  testWidgets('changing the allowance and buffer saves both', (tester) async {
    final world = await pumpApp(tester);
    await openSettings(tester);
    await tester.tap(find.text('Allowance and buffer'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'Weekly allowance'), '7500');
    await tester.enterText(find.widgetWithText(TextFormField, 'Keep at least (optional)'), '');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect((world.settings!.weeklyCap, world.settings!.buffer), (7500, 0));
    expect(world.settings!.openingDate, demoSettings.openingDate);
    expect(find.text('RM75 a week'), findsOneWidget, reason: 'no buffer, so no keep');
  });

  testWidgets('an empty allowance is refused', (tester) async {
    final world = await pumpApp(tester);
    await openSettings(tester);
    await tester.tap(find.text('Allowance and buffer'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'Weekly allowance'), '');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(find.text('Enter how much you allow each week'), findsOneWidget);
    expect(world.settings!.weeklyCap, demoSettings.weeklyCap);
  });

  testWidgets('the app can be set to light or dark instead of following the phone', (tester) async {
    final world = await pumpApp(tester);
    await openSettings(tester);
    await tester.drag(find.byType(ListView), const Offset(0, -1500));
    await tester.pumpAndSettle();
    expect(find.text('Match the phone'), findsOneWidget);

    await tester.tap(find.text('Appearance'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();

    expect(world.themeModes.saved, ThemeMode.dark);
    expect(tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode, ThemeMode.dark);
    expect(Theme.of(tester.element(find.text('Appearance'))).brightness, Brightness.dark);
    expect(find.text('Dark'), findsOneWidget);
  });
}
