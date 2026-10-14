import 'package:bajet/features/plan/presentation/runway_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/app_harness.dart';

DateTime d(int y, int m, int day) => DateTime.utc(y, m, day);

Future<void> openRunway(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('tab-Runway')));
  await tester.pumpAndSettle();
}

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
    expect(find.text('RM1,000.00'), findsOneWidget);
    expect(find.text('RM500.00 above your RM500 buffer'), findsOneWidget);
    // The buffer line is named in a legend, not inside the chart.
    expect(find.text('Keep at least RM500'), findsOneWidget);
  });

  testWidgets('a goal short of the buffer says by how much', (tester) async {
    await pumpApp(tester, seed: (w) => w.addGoal(name: 'Laptop', price: 120000, targetDate: d(2026, 7, 31)));
    await openRunway(tester);
    expect(find.text('RM200.00 short of your RM500 buffer'), findsOneWidget);
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
}
