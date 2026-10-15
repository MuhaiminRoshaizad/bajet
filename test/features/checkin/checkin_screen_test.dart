import 'package:bajet/features/ledger/domain/ledger_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/app_harness.dart';

Future<void> openCheckin(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Settings'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Sunday check-in'));
  await tester.pumpAndSettle();
}

Finder bankField() => find.widgetWithText(TextFormField, 'Bank app says');

void main() {
  testWidgets('a matching bank balance is confirmed', (tester) async {
    await pumpApp(tester);
    await openCheckin(tester);
    expect(find.text('RM1,500.00'), findsOneWidget);

    await tester.enterText(bankField(), '150000');
    await tester.pumpAndSettle();
    expect(find.text('Matches exactly'), findsOneWidget);
  });

  testWidgets('money missing from the bank can be logged as untracked', (tester) async {
    final world = await pumpApp(tester);
    await openCheckin(tester);
    await tester.enterText(bankField(), '148000');
    await tester.pumpAndSettle();
    expect(find.text('RM20.00 spent but not logged'), findsOneWidget);

    await tester.ensureVisible(find.text('Log RM20.00 as untracked'));
    await tester.tap(find.text('Log RM20.00 as untracked'));
    await tester.pumpAndSettle();

    final e = world.entries.single;
    expect((e.amount, e.categoryKey, e.isIncome), (2000, untrackedCategoryKey, false));
    expect(find.text('Matches exactly'), findsOneWidget);
  });

  testWidgets('extra money in the bank opens the logger as income, filled in', (tester) async {
    await pumpApp(tester);
    await openCheckin(tester);
    await tester.enterText(bankField(), '151000');
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Log the income'));
    await tester.tap(find.text('Log the income'));
    await tester.pumpAndSettle();
    expect(find.text('RM10.00'), findsWidgets);
    expect(find.bySemanticsLabel('Salary'), findsOneWidget);
  });

  testWidgets('Today does not offer the check-in midweek', (tester) async {
    await pumpApp(tester);
    expect(find.text('Sunday check-in'), findsNothing);
  });
}
