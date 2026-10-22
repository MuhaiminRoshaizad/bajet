import 'package:bajet/core/storage/device_flags.dart';
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
    // Opened from inside the tab, the logger still sits over the floating
    // bar, so the button at its foot can be reached.
    expect(find.widgetWithText(FilledButton, 'Type the amount').hitTestable(), findsOneWidget);
    expect(find.byKey(const ValueKey('add')).hitTestable(), findsNothing);
  });

  testWidgets("a tip shows until hidden, and Undo brings tips back", (tester) async {
    final world = await pumpApp(tester, seed: (w) => w.add(EntryDraft(day: testToday, isIncome: false, amount: 800, categoryKey: 'food')));
    await openInsights(tester);
    expect(find.text('Good to know'), findsOneWidget);
    // Midway up the screen, clear of the floating bar.
    await Scrollable.ensureVisible(tester.element(find.text('Hide tips')), alignment: 0.5);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hide tips'));
    await settleUnderBar(tester);
    expect(find.text('Good to know'), findsNothing);
    expect(world.flags.on, contains(DeviceFlag.tipsHidden));
    expect(find.text('Tips hidden'), findsOneWidget);
    await tester.tap(find.text('Undo'));
    await settleUnderBar(tester);
    expect(find.text('Good to know'), findsOneWidget);
  });

  testWidgets('spending splits by kind, and a part opens its entries', (tester) async {
    await pumpApp(tester, seed: (w) {
      w.add(EntryDraft(day: testToday, isIncome: false, amount: 800, categoryKey: 'food', label: 'Lunch'));
      w.add(EntryDraft(day: testToday, isIncome: false, amount: 4500, categoryKey: 'family', label: 'Groceries', spendKind: SpendKind.need));
    });
    await openInsights(tester);
    expect(find.text('Spending by kind'), findsOneWidget);
    expect(find.textContaining('Needs · bought anyway or asked for'), findsOneWidget);
    expect(find.byKey(const ValueKey(('drawer-entry', 2))), findsNothing);
    await tester.ensureVisible(find.byKey(const ValueKey('part-needs')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('part-needs')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey(('drawer-entry', 2))), findsOneWidget);
    expect(find.byKey(const ValueKey(('drawer-entry', 1))), findsNothing, reason: 'the want stays under Wants');
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
    await tester.tap(find.text('Week'));
    await tester.pumpAndSettle();
    expect(labelled('Food RM8.00'), findsOneWidget);
  });

  testWidgets('the arrows step back to an earlier month, and its label jumps back to this one', (tester) async {
    await pumpApp(tester, seed: (w) {
      // Logged back into June, before the opening date of 01/07/2026.
      w.add(EntryDraft(day: d(6, 20), isIncome: false, amount: 1500, categoryKey: 'food', label: 'Dinner'));
      w.add(EntryDraft(day: testToday, isIncome: false, amount: 800, categoryKey: 'food'));
    });
    await openInsights(tester);
    expect(find.text('July 2026'), findsOneWidget);
    expect(tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.chevron_right_rounded)).onPressed, isNull);

    await tester.tap(find.byTooltip('Earlier month'));
    await tester.pumpAndSettle();
    expect(find.text('June 2026'), findsOneWidget);
    expect(labelled('Food RM15.00'), findsOneWidget);
    // June is the first month with anything logged, so the way back ends.
    expect(tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.chevron_left_rounded)).onPressed, isNull);

    await tester.tap(find.text('Back to this month'));
    await tester.pumpAndSettle();
    expect(find.text('July 2026'), findsOneWidget);
    expect(labelled('Food RM8.00'), findsOneWidget);
  });

  testWidgets('switching to Week lands on the current week, and Share takes the range shown', (tester) async {
    await pumpApp(tester, seed: (w) => w.add(EntryDraft(day: d(6, 20), isIncome: false, amount: 1500, categoryKey: 'food')));
    await openInsights(tester);
    await tester.tap(find.byTooltip('Earlier month'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Week'));
    await tester.pumpAndSettle();
    expect(find.text('This week · so far'), findsOneWidget);

    await tester.tap(find.byTooltip('Earlier week'));
    await tester.pumpAndSettle();
    expect(find.text('22/06 to 28/06/2026'), findsOneWidget);
    await tester.tap(find.byTooltip('Share a report'));
    await tester.pumpAndSettle();
    expect(find.text('22/06 to 28/06/2026'), findsOneWidget);
    expect(find.textContaining('bajet report, 22/06/2026 to 28/06/2026'), findsOneWidget);
  });
}
