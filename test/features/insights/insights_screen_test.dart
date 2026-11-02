import 'package:bajet/core/dates/dates.dart';
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
    expect(find.textContaining('Not my call · you had no real say'), findsOneWidget);
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

  testWidgets("the goal card names the price and the buffer it adds", (tester) async {
    await pumpApp(tester, seed: (w) {
      w.add(EntryDraft(day: testToday, isIncome: false, amount: 800, categoryKey: 'food', label: 'Lunch'));
      w.addGoal(name: 'Bicycle', price: 200000, targetDate: DateTime.utc(testToday.year + 1, 1, 1));
    });
    await openInsights(tester);
    await tester.scrollUntilVisible(find.text('Toward Bicycle'), 300, scrollable: find.byType(Scrollable).first);
    expect(find.textContaining('RM2,000.00 price + RM'), findsOneWidget);
  });

  testWidgets('a tapped day in the last 14 days names itself and opens what was spent, and a second tap closes it', (tester) async {
    final yesterday = DateTime.utc(testToday.year, testToday.month, testToday.day - 1);
    await pumpApp(tester, seed: (w) {
      w.add(EntryDraft(day: yesterday, isIncome: false, amount: 750, categoryKey: 'food', label: 'Lunch'));
      w.add(EntryDraft(day: yesterday, isIncome: false, amount: 4500, categoryKey: 'personal', label: 'Repair', spendKind: SpendKind.need));
      w.add(EntryDraft(day: testToday, isIncome: false, amount: 300, categoryKey: 'food', label: 'Coffee'));
    });
    await openInsights(tester);
    await tester.scrollUntilVisible(find.text('Last 14 days'), 300, scrollable: find.byType(Scrollable).first);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -150));
    await tester.pumpAndSettle();
    // The first day's date, at the chart's left end until a day is tapped.
    final firstDay = find.text(Dates.short(DateTime.utc(testToday.year, testToday.month, testToday.day - 13)));
    expect(firstDay, findsOneWidget);
    final chart = tester.getRect(find.descendant(of: find.ancestor(of: find.text('Last 14 days'), matching: find.byType(Column)).first, matching: find.byType(GestureDetector)).last);
    final slot = chart.width / 14;
    await tester.tapAt(Offset(chart.left + slot * 12.5, chart.center.dy));
    await tester.pumpAndSettle();
    expect(firstDay, findsNothing);
    expect(find.text('${Dates.weekday(yesterday)} ${Dates.short(yesterday)}'), findsOneWidget);
    expect(find.text('Lunch'), findsOneWidget);
    expect(find.text('Coffee'), findsNothing, reason: "today's bar is not open");
    expect(find.textContaining('Also RM45.00 not my call or planned'), findsOneWidget);
    await tester.tapAt(Offset(chart.left + slot * 12.5, chart.center.dy));
    await tester.pumpAndSettle();
    expect(firstDay, findsOneWidget);
    expect(find.text('Lunch'), findsNothing);
  });
}
