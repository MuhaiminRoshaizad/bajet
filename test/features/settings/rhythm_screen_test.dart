import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/app_harness.dart';

Future<void> openRhythm(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Settings'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Weekly rhythm'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('lists all seven days with what they cost', (tester) async {
    await pumpApp(tester);
    await openRhythm(tester);
    for (final day in ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']) {
      expect(find.text(day), findsOneWidget);
    }
    expect(find.textContaining('Planned in total: RM0.00 a week.'), findsOneWidget);
  });

  testWidgets('editing a day saves its name, type, amount and fasting mark', (tester) async {
    await pumpApp(tester);
    await openRhythm(tester);
    await tester.tap(find.text('Monday'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'Name'), 'Office day');
    await tester.tap(find.text('Flexible'));
    await tester.enterText(find.widgetWithText(TextFormField, 'Planned spend'), '1200');
    await tester.tap(find.text('Fasting day'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Planned in total: RM12.00 a week.'), findsOneWidget);
    expect(find.text('Office day · Flexible · fasting'), findsOneWidget);
  });
}
