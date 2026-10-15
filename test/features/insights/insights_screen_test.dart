import 'package:bajet/features/ledger/domain/ledger_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/app_harness.dart';

DateTime d(int m, int day) => DateTime.utc(2026, m, day);

/// Matches the label a widget gives itself, on screen or not.
Finder labelled(String label) => find.byWidgetPredicate((w) => w is Semantics && w.properties.label == label);

Future<void> openInsights(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('tab-Insights')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('with nothing logged it says so and how to start', (tester) async {
    await pumpApp(tester);
    await openInsights(tester);
    expect(find.text('Nothing logged this month'), findsOneWidget);
    // It fills the space under the period switch, centred rather than at the top.
    final y = tester.getCenter(find.text('Nothing logged this month')).dy;
    expect(y, inInclusiveRange(250, 450));

    await tester.tap(find.text('Log a spend'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(FilledButton, 'Type the amount'), findsOneWidget);
  });

  testWidgets('shows money in and out and where the flexible money went', (tester) async {
    await pumpApp(tester, seed: (w) {
      w.add(EntryDraft(day: testToday, isIncome: true, amount: 300000, categoryKey: 'salary'));
      w.add(EntryDraft(day: testToday, isIncome: false, amount: 800, categoryKey: 'food', label: 'Lunch'));
    });
    await openInsights(tester);
    expect(find.text('RM3,000.00'), findsOneWidget);
    expect(labelled('Food RM8.00'), findsOneWidget);
  });

  testWidgets('switching to this week narrows the period', (tester) async {
    await pumpApp(tester, seed: (w) => w.add(EntryDraft(day: testToday, isIncome: false, amount: 800, categoryKey: 'food')));
    await openInsights(tester);
    await tester.tap(find.text('This week'));
    await tester.pumpAndSettle();
    expect(labelled('Food RM8.00'), findsOneWidget);
  });
}
