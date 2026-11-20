import 'package:bajet/features/ledger/domain/ledger_models.dart';
import 'package:bajet/features/plan/domain/plan_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/fake_repositories.dart';

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

  testWidgets('the week dial counts wants against the allowance', (tester) async {
    await pumpApp(tester, seed: (w) {
      // Monday of this week, a want; a bill and a need, which do not count.
      w.add(EntryDraft(day: d(2026, 6, 29), isIncome: false, amount: 1500, categoryKey: 'transport'));
      w.add(EntryDraft(day: testToday, isIncome: false, amount: 9000, categoryKey: 'bills'));
      w.add(EntryDraft(day: testToday, isIncome: false, amount: 4500, categoryKey: 'family', spendKind: SpendKind.need));
    });
    expect(find.text('RM35.00'), findsOneWidget);
    expect(find.text('left this week'), findsOneWidget);
    expect(find.text('Spent RM15.00 of RM50'), findsOneWidget);
  });

  testWidgets("the week's needs show under the dial, and a tap lists them", (tester) async {
    await pumpApp(tester, seed: (w) {
      w.add(EntryDraft(day: testToday, isIncome: false, amount: 1500, categoryKey: 'food'));
      w.add(EntryDraft(day: testToday, isIncome: false, amount: 4500, categoryKey: 'family', label: 'Groceries', spendKind: SpendKind.need));
      w.add(EntryDraft(day: d(2026, 6, 28), isIncome: false, amount: 900, categoryKey: 'family', spendKind: SpendKind.need));
    });
    expect(find.text('RM45.00'), findsOneWidget, reason: "last week's need is not this week's");
    expect(find.text('Also this week, not counted in your RM50'), findsOneWidget);
    expect(find.byKey(const ValueKey(('drawer-entry', 2))), findsNothing);
    await tester.tap(find.text('Also this week, not counted in your RM50'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey(('drawer-entry', 2))), findsOneWidget);
  });

  testWidgets('a week with no needs shows no needs line', (tester) async {
    await pumpApp(tester, seed: (w) => w.add(EntryDraft(day: testToday, isIncome: false, amount: 1500, categoryKey: 'food')));
    expect(find.textContaining('not counted in your'), findsNothing);
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

  testWidgets('Paid opens the log sheet with the bill picked, so the real amount is what is logged; Undo makes it due again', (tester) async {
    final world = await pumpApp(tester, seed: (w) {
      w.addRecurring(name: 'Internet', isIncome: false, amount: 12900, categoryKey: 'bills', nextDue: testToday);
    });
    expect(find.text('Internet'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Paid'));
    await tester.pumpAndSettle();
    expect(world.entries, isEmpty, reason: 'nothing is logged until the sheet is saved');
    expect(find.text('Log RM129.00'), findsOneWidget);

    // This month's bill came to a little more.
    await tester.enterText(find.byKey(const ValueKey('amount')), '13450');
    await tester.pump();
    await tester.tap(find.text('Log RM134.50'));
    await settleUnderBar(tester);
    expect((world.entries.single.amount, world.recurring.single.nextDue), (13450, d(2026, 8, 1)));
    expect(find.widgetWithText(FilledButton, 'Paid'), findsNothing);
    expect(find.text('Paid Internet RM134.50'), findsOneWidget);

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

  group('a spend partly for others', () {
    void seedLunch(FakeWorld w) {
      w.add(EntryDraft(day: testToday, isIncome: false, amount: 1500, forOthers: 5250, categoryKey: 'food', label: 'Lunch'));
      w.addPayback(entryId: 1, day: testToday, amount: 1750);
    }

    testWidgets('shows what is still owed, and Paid back opens the sheet with it picked', (tester) async {
      await pumpApp(tester, seed: seedLunch);
      expect(find.text('Lunch · 01/07'), findsOneWidget);
      expect(find.text('RM35.00 still owed to you'), findsOneWidget);
      expect(find.text('RM17.50 of RM52.50 back'), findsOneWidget);
      // The whole RM67.50 left the account; only RM17.50 has come back.
      expect(find.bySemanticsLabel(RegExp(r'Total balance RM1,450.00')), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Paid back'));
      await tester.pumpAndSettle();
      expect(find.text('RM35.00 owed · 01/07'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'From (optional)'), findsOneWidget);
    });

    testWidgets("Let it go asks, makes the rest the user's own, and Undo puts it back", (tester) async {
      final world = await pumpApp(tester, seed: seedLunch);
      await tester.ensureVisible(find.text('Let it go'));
      await tester.tap(find.text('Let it go'));
      await tester.pumpAndSettle();
      expect(find.text('The RM35.00 still owed for Lunch becomes your own Food spending on 01/07/2026.'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Let it go'));
      await settleUnderBar(tester);
      expect(find.text('Let go of RM35.00 for Lunch'), findsOneWidget);
      expect((world.entries.single.amount, world.entries.single.forOthers), (5000, 1750));
      expect(find.text('Lunch · 01/07'), findsNothing);

      await tester.tap(find.text('Undo'));
      await settleUnderBar(tester);
      expect((world.entries.single.amount, world.entries.single.forOthers), (1500, 5250));
      expect(find.text('Lunch · 01/07'), findsOneWidget);
    });
  });
}
