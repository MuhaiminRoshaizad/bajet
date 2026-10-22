import 'package:bajet/features/plan/domain/plan_repository.dart';
import 'package:bajet/features/plan/presentation/runway_chart.dart';
import 'package:bajet/features/plan/presentation/runway_sums.dart';
import 'package:bajet/features/ledger/domain/ledger_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/app_harness.dart';

DateTime d(int y, int m, int day) => DateTime.utc(y, m, day);

Future<void> openRunway(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('tab-Runway')));
  await tester.pumpAndSettle();
}

/// The big figure on the outcome card, not the same amount in the sums below it.
Finder headline(String text) => find.byWidgetPredicate((w) => w is Text && w.data == text && w.style?.fontSize == 30);

Finder inSums(String text) => find.descendant(of: find.byType(RunwaySumsCard), matching: find.text(text));

void main() {
  testWidgets('without a goal it charts 30 days and asks for a goal', (tester) async {
    await pumpApp(tester);
    await openRunway(tester);
    expect(find.byType(RunwayChart), findsOneWidget);
    expect(find.text('Your balance over the next 30 days'), findsOneWidget);
    expect(find.text('Add a goal to see what would be left after buying it.'), findsOneWidget);
  });

  testWidgets('with a goal it shows what is left against the buffer', (tester) async {
    await pumpApp(tester, seed: (w) => w.addGoal(name: 'Laptop', price: 50000, targetDate: d(2026, 7, 31)));
    await openRunway(tester);
    expect(find.text('Left after buying Laptop'), findsOneWidget);
    expect(headline('RM1,000.00'), findsOneWidget);
    expect(find.text('RM500.00 above your RM500 buffer'), findsOneWidget);
    // The buffer line is named in a legend, not inside the chart.
    expect(find.text('Keep at least RM500'), findsOneWidget);
  });

  testWidgets('a goal short of the buffer says by how much', (tester) async {
    await pumpApp(tester, seed: (w) => w.addGoal(name: 'Laptop', price: 120000, targetDate: d(2026, 7, 31)));
    await openRunway(tester);
    expect(find.text('RM200.00 short of your RM500 buffer'), findsOneWidget);
  });

  testWidgets('shows how what is left adds up, and says when no income is planned', (tester) async {
    // Wed 1 Jul to Fri 31 Jul is 31 days with the harness's RM0 rhythm.
    await pumpApp(tester, seed: (w) => w.addGoal(name: 'Laptop', price: 120000, targetDate: d(2026, 7, 31)));
    await openRunway(tester);
    await tester.scrollUntilVisible(find.text('How it adds up'), 200);
    expect(find.text('Balance today'), findsOneWidget);
    expect(find.text('Laptop price'), findsOneWidget);
    expect(inSums('−RM1,200.00'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Add monthly income'), 200);
    expect(find.textContaining('No income is planned before buy day'), findsOneWidget);
  });

  testWidgets('a monthly amount for needs is its own line, and only when set', (tester) async {
    final world = await pumpApp(tester, seed: (w) {
      w.addGoal(name: 'Laptop', price: 50000, targetDate: d(2026, 7, 31));
      w.saveSettings(PlanSettings(openingDate: testToday, weeklyCap: 5000, buffer: 50000, needsReserve: 3100));
    });
    await openRunway(tester);
    // RM1.00 a day for 2 to 31 July.
    expect(headline('RM970.00'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('How it adds up'), 200);
    expect(find.text('Needs until buy day'), findsOneWidget);
    expect(inSums('−RM30.00'), findsOneWidget);
    await world.saveSettings(PlanSettings(openingDate: testToday, weeklyCap: 5000, buffer: 50000));
    await tester.pumpAndSettle();
    expect(find.text('Needs until buy day'), findsNothing);
  });

  testWidgets('planned income is counted and the warning goes', (tester) async {
    await pumpApp(tester, seed: (w) {
      w.addGoal(name: 'Laptop', price: 120000, targetDate: d(2026, 7, 31));
      w.addRecurring(name: 'Salary', isIncome: true, amount: 300000, categoryKey: 'salary', nextDue: d(2026, 7, 25));
    });
    await openRunway(tester);
    await tester.scrollUntilVisible(find.text('How it adds up'), 200);
    expect(inSums('+RM3,000.00'), findsOneWidget);
    expect(find.textContaining('No income is planned'), findsNothing);
  });

  testWidgets('lists what is coming up, soonest first', (tester) async {
    await pumpApp(tester, seed: (w) {
      w.addRecurring(name: 'Rent', isIncome: false, amount: 50000, categoryKey: 'bills', nextDue: d(2026, 7, 5));
      w.addGoal(name: 'Laptop', price: 50000, targetDate: d(2026, 8, 20));
    });
    await openRunway(tester);
    await tester.dragUntilVisible(find.text('Thu 20/08/2026'), find.byType(ListView).first, const Offset(0, -200));
    await tester.ensureVisible(find.text('Thu 20/08/2026'));
    await tester.pumpAndSettle();
    final rent = tester.getTopLeft(find.text('Sun 05/07/2026')).dy;
    final laptop = tester.getTopLeft(find.text('Thu 20/08/2026')).dy;
    expect(rent, lessThan(laptop));
    expect(find.text('Wed 05/08/2026'), findsOneWidget);
    expect(find.text('buy day'), findsOneWidget);
    // Three items fit, so there is nothing to open.
    expect(find.textContaining(RegExp(r'^Show \d+ more$')), findsNothing);
  });

  testWidgets('only four items show until opened, and Show less closes them again', (tester) async {
    await pumpApp(tester, seed: (w) {
      for (final (i, name) in ['Rent', 'Phone', 'Internet', 'Water', 'Power', 'Gym'].indexed) {
        w.addRecurring(name: name, isIncome: false, amount: 1000 + i, categoryKey: 'bills', nextDue: d(2026, 7, 5 + i));
      }
    });
    await openRunway(tester);
    final more = find.text('Show 2 more');
    await tester.dragUntilVisible(more, find.byType(ListView).first, const Offset(0, -200));
    await tester.ensureVisible(more);
    await tester.pumpAndSettle();
    expect(find.text('Power'), findsNothing);

    await tester.tap(more);
    await tester.pumpAndSettle();
    expect(find.text('Power'), findsOneWidget);
    expect(find.text('Gym'), findsOneWidget);

    await tester.ensureVisible(find.text('Show less'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Show less'));
    await tester.pumpAndSettle();
    expect(find.text('Power'), findsNothing);
    expect(find.text('Show 2 more'), findsOneWidget);
  });

  testWidgets('bills on the same day share one heading with the day\'s total', (tester) async {
    await pumpApp(tester, seed: (w) {
      w.addRecurring(name: 'Rent', isIncome: false, amount: 50000, categoryKey: 'bills', nextDue: d(2026, 7, 5));
      w.addRecurring(name: 'Phone', isIncome: false, amount: 4800, categoryKey: 'bills', nextDue: d(2026, 7, 5));
    });
    await openRunway(tester);
    await tester.dragUntilVisible(find.text('Phone'), find.byType(ListView).first, const Offset(0, -200));
    expect(find.text('Sun 05/07/2026'), findsOneWidget);
    expect(find.text('−RM548.00'), findsOneWidget);
  });

  testWidgets('a date with one item does not repeat its amount in the heading', (tester) async {
    await pumpApp(tester, seed: (w) => w.addRecurring(name: 'Rent', isIncome: false, amount: 50000, categoryKey: 'bills', nextDue: d(2026, 7, 5)));
    await openRunway(tester);
    await tester.dragUntilVisible(find.text('Sun 05/07/2026'), find.byType(ListView).first, const Offset(0, -200));
    expect(find.text('−RM500.00'), findsOneWidget);
  });

  testWidgets('a what-if moves buy day without changing the plan, and resets', (tester) async {
    final world = await pumpApp(tester, seed: (w) => w.addGoal(name: 'Laptop', price: 50000, targetDate: d(2026, 8, 15)));
    await openRunway(tester);
    expect(headline('RM1,000.00'), findsOneWidget);

    // A new monthly cost: drag the second slider to its far end, RM300.
    final monthly = find.byType(Slider).at(1);
    // Scroll it well clear of the bottom bar before dragging it.
    await tester.ensureVisible(monthly);
    await tester.drag(find.byType(ListView).first, const Offset(0, -300));
    await tester.pumpAndSettle();
    await tester.drag(monthly, const Offset(1000, 0));
    await tester.pumpAndSettle();
    expect(find.text('RM300 a month'), findsOneWidget);
    // Today is 01/07 itself, so the first cost lands on 01/08, before buy day.
    expect(headline('RM700.00'), findsOneWidget);
    expect(find.text('−RM300.00 compared with the plan'), findsOneWidget);
    expect(world.events, isEmpty);

    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();
    expect(headline('RM1,000.00'), findsOneWidget);
  });

  testWidgets('the calendar marks planned days and lists a tapped day', (tester) async {
    await pumpApp(tester, seed: (w) {
      w.addRecurring(name: 'Salary', isIncome: true, amount: 300000, categoryKey: 'salary', nextDue: d(2026, 7, 25));
      w.addRecurring(name: 'Rent', isIncome: false, amount: 50000, categoryKey: 'bills', nextDue: d(2026, 7, 5));
      w.addGoal(name: 'Laptop', price: 50000, targetDate: d(2026, 8, 20));
    });
    await openRunway(tester);
    await tester.dragUntilVisible(find.text('Calendar'), find.byType(ListView).first, const Offset(0, -200));
    await tester.ensureVisible(find.text('Calendar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Calendar'));
    await tester.pumpAndSettle();

    // July opens on its first planned day.
    expect(find.text('July 2026'), findsOneWidget);
    expect(find.text('Sunday 5 July'), findsOneWidget);
    expect(find.bySemanticsLabel('Sat 25/07/2026, 1 planned'), findsOneWidget);

    await tester.ensureVisible(find.bySemanticsLabel('Sat 25/07/2026, 1 planned'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Sat 25/07/2026, 1 planned'));
    await tester.pumpAndSettle();
    expect(find.text('Saturday 25 July'), findsOneWidget);
    expect(find.text('Salary'), findsOneWidget);

    await tester.ensureVisible(find.byTooltip('Next month'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Next month'));
    await tester.pumpAndSettle();
    expect(find.text('August 2026'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('20/08/2026.*buy day')), findsOneWidget);
    // Buy day is the last month there is.
    expect(tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.chevron_right_rounded)).onPressed, isNull);
  });

  testWidgets('the calendar opens on the month of the first thing planned', (tester) async {
    await pumpApp(tester, seed: (w) {
      w.addRecurring(name: 'Salary', isIncome: true, amount: 300000, categoryKey: 'salary', nextDue: d(2026, 8, 3));
      w.addGoal(name: 'Laptop', price: 50000, targetDate: d(2026, 8, 20));
    });
    await openRunway(tester);
    await tester.dragUntilVisible(find.text('Calendar'), find.byType(ListView).first, const Offset(0, -200));
    await tester.ensureVisible(find.text('Calendar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Calendar'));
    await tester.pumpAndSettle();
    expect(find.text('August 2026'), findsOneWidget);
    expect(find.text('Monday 3 August'), findsOneWidget);
    // July is still there to look back at.
    expect(tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.chevron_left_rounded)).onPressed, isNotNull);
  });

  testWidgets('Coming up counts only what is left of an event budget', (tester) async {
    await pumpApp(tester, seed: (w) {
      w.addEvent(name: 'Birthday', isIncome: false, amount: 10000, categoryKey: 'gifts', date: d(2026, 7, 20));
      w.add(EntryDraft(day: testToday, isIncome: false, amount: 7300, categoryKey: 'food', event: EventLink(w.events.single.id, d(2026, 7, 20))));
    });
    await openRunway(tester);
    await tester.dragUntilVisible(find.text('Birthday'), find.byType(ListView).first, const Offset(0, -200));
    expect(find.text('RM73.00 of RM100.00 spent'), findsOneWidget);
    expect(find.text('−RM27.00'), findsOneWidget);
  });
}
