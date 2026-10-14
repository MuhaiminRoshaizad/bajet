import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/app_harness.dart';

DateTime d(int y, int m, int day) => DateTime.utc(y, m, day);

void main() {
  testWidgets("Today's empty goal card leads to adding one", (tester) async {
    await pumpApp(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Add a goal'));
    await tester.pumpAndSettle();
    expect(find.text('Goals'), findsOneWidget);
  });

  testWidgets('goals are listed in priority order with their status', (tester) async {
    await pumpApp(tester, seed: (w) {
      w.addGoal(name: 'Laptop', price: 50000, targetDate: d(2026, 7, 31), priority: 1);
      w.addGoal(name: 'Holiday', price: 20000, targetDate: d(2026, 9, 30), priority: 2);
    });
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Goals'));
    await tester.pumpAndSettle();

    expect(find.text('RM500.00 by 31/07/2026 · on track'), findsOneWidget);
    expect(tester.getTopLeft(find.text('Laptop')).dy, lessThan(tester.getTopLeft(find.text('Holiday')).dy));
  });

  testWidgets('marking a goal bought asks first, then logs the price', (tester) async {
    final world = await pumpApp(tester, seed: (w) => w.addGoal(name: 'Laptop', price: 50000, targetDate: d(2026, 7, 31)));
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Goals'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Bought'));
    await tester.pumpAndSettle();
    expect(find.text('Mark Laptop as bought?'), findsOneWidget);
    await tester.tap(find.text('Not yet'));
    await tester.pumpAndSettle();
    expect(world.goals, hasLength(1));

    await tester.tap(find.text('Bought'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mark bought'));
    await tester.pumpAndSettle();
    expect(world.goals, isEmpty);
    expect((world.entries.single.amount, world.entries.single.label), (50000, 'Laptop'));
  });

  testWidgets('a new goal needs a name, price and buy day', (tester) async {
    final world = await pumpApp(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Add a goal'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Add a goal'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save goal'));
    await tester.pumpAndSettle();
    expect(find.text('Give the goal a name'), findsOneWidget);
    expect(find.text('Enter the price'), findsOneWidget);
    expect(find.text('Pick the day you plan to buy it'), findsOneWidget);
    expect(world.goals, isEmpty);
  });

  testWidgets('a bought goal moves to Done with its date and price', (tester) async {
    await pumpApp(tester, seed: (w) => w.addGoal(name: 'Laptop', price: 50000, targetDate: d(2026, 7, 31)));
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Goals'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bought'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mark bought'));
    await tester.pumpAndSettle();

    expect(find.text('Done'), findsOneWidget);
    expect(find.text('Bought 01/07/2026 for RM500.00'), findsOneWidget);
  });

  testWidgets('holding and dragging a goal changes which is bought first', (tester) async {
    final world = await pumpApp(tester, seed: (w) {
      w.addGoal(name: 'Laptop', price: 50000, targetDate: d(2026, 7, 31), priority: 1);
      w.addGoal(name: 'Holiday', price: 20000, targetDate: d(2026, 9, 30), priority: 2);
    });
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Goals'));
    await tester.pumpAndSettle();

    final drag = await tester.startGesture(tester.getCenter(find.text('Holiday')));
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
    // In steps, so the list sees the item travel over the one above it.
    for (var i = 0; i < 10; i++) {
      await drag.moveBy(const Offset(0, -30));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await tester.pumpAndSettle();
    await drag.up();
    await tester.pumpAndSettle();

    expect([for (final g in world.goals..sort((a, b) => a.priority.compareTo(b.priority))) g.name], ['Holiday', 'Laptop']);
  });
}
