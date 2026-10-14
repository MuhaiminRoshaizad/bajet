import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/app_harness.dart';

Finder field(String label) => find.widgetWithText(TextFormField, label);

Future<void> fillMoneyStep(WidgetTester tester) async {
  await tester.enterText(field('Balance today'), '250000');
  await tester.enterText(field('Weekly allowance'), '5000');
  await tester.tap(find.text('Continue'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a new install opens on setup, not Today', (tester) async {
    await pumpApp(tester, setUpDone: false);
    expect(find.text('Your money'), findsOneWidget);
    expect(find.byKey(const ValueKey('tab-Today')), findsNothing);
  });

  testWidgets('required fields are flagged only when Continue is pressed', (tester) async {
    await pumpApp(tester, setUpDone: false);
    expect(find.text('Enter your balance today'), findsNothing);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Enter your balance today'), findsOneWidget);
    expect(find.text('Enter how much you allow each week'), findsOneWidget);
  });

  testWidgets('an error clears as soon as the value becomes valid', (tester) async {
    await pumpApp(tester, setUpDone: false);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    await tester.enterText(field('Balance today'), '250000');
    await tester.pumpAndSettle();
    expect(find.text('Enter your balance today'), findsNothing);
    expect(find.text('2,500.00'), findsOneWidget);
  });

  testWidgets('skipping the goal saves settings and lands on Today', (tester) async {
    final world = await pumpApp(tester, setUpDone: false);
    await fillMoneyStep(tester);

    expect(find.text('Your first goal'), findsOneWidget);
    await tester.tap(find.text('Skip for now'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('tab-Today')), findsOneWidget);
    final s = world.settings!;
    expect((s.openingBalance, s.weeklyCap, s.buffer, s.openingDate), (250000, 5000, 0, testToday));
    expect(world.goals, isEmpty);
  });

  testWidgets('a half-filled goal cannot be skipped by accident', (tester) async {
    await pumpApp(tester, setUpDone: false);
    await fillMoneyStep(tester);

    await tester.enterText(field('Goal'), 'Laptop');
    await tester.pumpAndSettle();
    expect(find.text('Clear the goal to skip it'), findsOneWidget);

    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();
    expect(find.text('Enter the price'), findsOneWidget);
    expect(find.text('Pick the day you plan to buy it'), findsOneWidget);
  });
}
