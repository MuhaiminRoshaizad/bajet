import 'package:bajet/features/plan/presentation/runway_chart.dart';
import 'package:bajet/features/plan/presentation/runway_sums.dart';
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
    final rent = tester.getTopLeft(find.text('Rent').first).dy;
    final laptop = tester.getTopLeft(find.text('Laptop')).dy;
    expect(rent, lessThan(laptop));
    expect(find.text('05/07/2026'), findsOneWidget);
    expect(find.text('05/08/2026'), findsOneWidget);
    expect(find.text('20/08/2026 · buy day'), findsOneWidget);
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
}
