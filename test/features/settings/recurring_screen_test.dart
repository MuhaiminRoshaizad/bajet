import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/app_harness.dart';

DateTime d(int y, int m, int day) => DateTime.utc(y, m, day);

Future<void> openRecurring(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Settings'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Bills and income'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('lists items with their amount and next due date', (tester) async {
    await pumpApp(tester, seed: (w) => w.addRecurring(name: 'Rent', isIncome: false, amount: 50000, categoryKey: 'bills', nextDue: d(2026, 8, 1)));
    await openRecurring(tester);
    expect(find.text('Rent'), findsOneWidget);
    expect(find.text('−RM500.00 · next 01/08/2026'), findsOneWidget);
  });

  testWidgets('switching an item off pauses it', (tester) async {
    final world = await pumpApp(tester, seed: (w) => w.addRecurring(name: 'Gym', isIncome: false, amount: 9000, categoryKey: 'bills', nextDue: d(2026, 8, 3)));
    await openRecurring(tester);
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(world.recurring.single.active, isFalse);
    expect(find.text('−RM90.00 · paused'), findsOneWidget);
  });

  testWidgets('saving a new item asks for everything it needs', (tester) async {
    final world = await pumpApp(tester);
    await openRecurring(tester);
    await tester.tap(find.text('Add a bill or income'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Save'));
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(find.text('Give it a name'), findsOneWidget);
    expect(find.text('Enter the amount'), findsOneWidget);
    expect(find.text('Pick a category'), findsWidgets);
    expect(find.text('Pick when it is next due'), findsOneWidget);
    expect(world.recurring, isEmpty);
  });

  testWidgets('income offers income categories only', (tester) async {
    await pumpApp(tester);
    await openRecurring(tester);
    await tester.tap(find.text('Add a bill or income'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Income').last);
    await tester.pumpAndSettle();
    expect(find.widgetWithText(ChoiceChip, 'Salary'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Bills'), findsNothing);
  });
}
