import 'package:bajet/features/ledger/domain/ledger_models.dart';
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
    await settleUnderBar(tester);

    await tester.enterText(find.widgetWithText(TextFormField, 'Weekly allowance, for your wants'), '7500');
    await tester.enterText(find.widgetWithText(TextFormField, 'Keep at least (optional)'), '');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await settleUnderBar(tester);

    expect((world.settings!.weeklyCap, world.settings!.buffer), (7500, 0));
    expect(world.settings!.openingDate, demoSettings.openingDate);
    expect(find.text('RM75 a week'), findsOneWidget, reason: 'no buffer, so no keep');
    expect(find.text('Allowance saved: RM75.00 a week'), findsOneWidget);
    await tester.tap(find.text('Undo'));
    await settleUnderBar(tester);
    expect((world.settings!.weeklyCap, world.settings!.buffer), (demoSettings.weeklyCap, demoSettings.buffer));
  });

  testWidgets('the monthly amount for needs saves, survives another change, and can come from the last four weeks', (tester) async {
    final world = await pumpApp(tester, seed: (w) {
      // RM28.00 of needs in four weeks is about RM30 a month.
      w.add(EntryDraft(day: testToday, isIncome: false, amount: 2800, categoryKey: 'family', spendKind: SpendKind.need));
    });
    await openSettings(tester);
    await tester.tap(find.text('Allowance and buffer'));
    await settleUnderBar(tester);
    final needs = find.widgetWithText(TextFormField, 'Needs, a month (optional)');
    expect(find.text('Use RM30.00, from your last 4 weeks'), findsOneWidget);
    await tester.tap(find.text('Use RM30.00, from your last 4 weeks'));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(find.descendant(of: needs, matching: find.byType(TextField))).controller!.text, '30.00');
    expect(find.text('Use RM30.00, from your last 4 weeks'), findsNothing);
    await tester.enterText(needs, '8000');
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Save'));
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await settleUnderBar(tester);
    expect(world.settings!.needsReserve, 8000);
    expect(find.text('Allowance saved: RM50.00 a week, RM80.00 a month for needs'), findsOneWidget);

    await tester.tap(find.text('Allowance and buffer'));
    await settleUnderBar(tester);
    await tester.enterText(find.widgetWithText(TextFormField, 'Weekly allowance, for your wants'), '4000');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await settleUnderBar(tester);
    expect((world.settings!.weeklyCap, world.settings!.needsReserve), (4000, 8000));
  });

  testWidgets('an empty allowance is refused', (tester) async {
    final world = await pumpApp(tester);
    await openSettings(tester);
    await tester.tap(find.text('Allowance and buffer'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'Weekly allowance, for your wants'), '');
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

  testWidgets('your name is set, changed and cleared from the top of Settings', (tester) async {
    final world = await pumpApp(tester);
    await openSettings(tester);
    expect(find.text('Not set · the coach uses no name'), findsOneWidget);

    await tester.tap(find.text('Your name'));
    await settleUnderBar(tester);
    expect(tester.testTextInput.isVisible, isFalse, reason: 'the keyboard waits for a tap');
    await tester.enterText(find.byKey(const ValueKey('user-name')), 'Sara');
    await tester.tap(find.text('Save'));
    await settleUnderBar(tester);
    expect(world.coachSettings.userName, 'Sara');
    expect(find.text('Sara'), findsOneWidget);
    expect(find.text('Saved. The coach will call you Sara'), findsOneWidget);

    await tester.tap(find.text('Your name'));
    await settleUnderBar(tester);
    await tester.enterText(find.byKey(const ValueKey('user-name')), '   ');
    await tester.tap(find.text('Save'));
    await settleUnderBar(tester);
    expect(world.coachSettings.userName, isNull);
    expect(find.text('Not set · the coach uses no name'), findsOneWidget);
    expect(find.text('Name cleared. The coach uses no name.'), findsOneWidget);
    await tester.tap(find.text('Undo'));
    await settleUnderBar(tester);
    expect(world.coachSettings.userName, 'Sara');
  });
}
