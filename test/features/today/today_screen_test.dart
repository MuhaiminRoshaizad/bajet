import 'package:bajet/features/ledger/domain/ledger_models.dart';
import 'package:bajet/features/plan/domain/plan_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/app_harness.dart';

DateTime d(int y, int m, int day) => DateTime.utc(y, m, day);

void main() {
  testWidgets('shows the balance from the opening balance and entries', (tester) async {
    await pumpApp(tester, seed: (w) {
      w.add(EntryDraft(day: testToday, isIncome: false, amount: 1250, categoryKey: 'food', label: 'Coffee'));
    });
    expect(find.bySemanticsLabel(RegExp(r'Total balance RM1,487.50')), findsOneWidget);
    expect(find.text('Coffee'), findsOneWidget);
  });

  testWidgets('an empty ledger says how to log the first spend', (tester) async {
    await pumpApp(tester);
    expect(find.text('Nothing logged yet. Tap + to log your first spend.'), findsOneWidget);
    expect(find.text('No goal yet'), findsOneWidget);
  });

  testWidgets('the week dial counts flexible spending against the allowance', (tester) async {
    await pumpApp(tester, seed: (w) {
      // Monday of this week, flexible; and a bill, which does not count.
      w.add(EntryDraft(day: d(2026, 6, 29), isIncome: false, amount: 1500, categoryKey: 'transport'));
      w.add(EntryDraft(day: testToday, isIncome: false, amount: 9000, categoryKey: 'bills'));
    });
    expect(find.text('RM35.00'), findsOneWidget);
    expect(find.text('left this week'), findsOneWidget);
    expect(find.text('Spent RM15.00 of RM50'), findsOneWidget);
  });

  testWidgets('a goal shows days left, what is left after buying and its status', (tester) async {
    await pumpApp(tester, seed: (w) => w.addGoal(name: 'Laptop', price: 50000, targetDate: d(2026, 7, 31)));
    expect(find.text('Laptop · buy day'), findsOneWidget);
    expect(find.text('30 days'), findsOneWidget);
    // RM1,500 opening, no planned spend, RM500 laptop: RM1,000 left, buffer RM500.
    expect(find.text('31/07/2026 · RM1,000.00 left after buying'), findsOneWidget);
    expect(find.text('On track'), findsOneWidget);
  });

  testWidgets('tapping the goal card opens Runway', (tester) async {
    await pumpApp(tester, seed: (w) => w.addGoal(name: 'Laptop', price: 50000, targetDate: d(2026, 7, 31)));
    await tester.tap(find.text('Laptop · buy day'));
    await tester.pumpAndSettle();
    expect(find.text('Left after buying Laptop'), findsOneWidget);
  });

  testWidgets('a due bill can be marked paid, which logs it, and Undo makes it due again', (tester) async {
    final world = await pumpApp(tester, seed: (w) {
      w.addRecurring(name: 'Internet', isIncome: false, amount: 12900, categoryKey: 'bills', nextDue: testToday);
    });
    expect(find.text('Internet'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Paid'));
    await tester.pumpAndSettle();

    expect(world.entries.single.amount, 12900);
    expect(world.recurring.single.nextDue, d(2026, 8, 1));
    expect(find.widgetWithText(FilledButton, 'Paid'), findsNothing);
    expect(find.text('Paid Internet RM129.00'), findsOneWidget);
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(world.entries, isEmpty);
    expect(world.recurring.single.nextDue, testToday);
    expect(find.widgetWithText(FilledButton, 'Paid'), findsOneWidget);
  });

  testWidgets("today's rule appears under the balance", (tester) async {
    await pumpApp(tester, seed: (w) => w.saveRule(const WeeklyRule(weekday: 3, label: 'Weekday', type: DayType.spend, plannedSpend: 1000)));
    expect(find.text('Weekday · up to RM10.00'), findsOneWidget);
  });

  testWidgets('with reduce motion on, cards appear without animating', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await pumpApp(tester);
    await tester.pump();
    expect(tester.hasRunningAnimations, isFalse);
    expect(find.text('No goal yet'), findsOneWidget);
  });
}
