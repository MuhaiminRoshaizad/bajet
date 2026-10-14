import 'package:flutter_test/flutter_test.dart';

import '../../helpers/app_harness.dart';

DateTime d(int y, int m, int day) => DateTime.utc(y, m, day);

Future<void> openEvents(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Settings'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Planned events'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('lists upcoming events, marking ones left out of the plan', (tester) async {
    await pumpApp(tester, seed: (w) {
      w.addEvent(name: 'Car service', isIncome: false, amount: 25000, categoryKey: 'transport', date: d(2026, 7, 20));
      w.addEvent(name: 'Bonus', isIncome: true, amount: 50000, categoryKey: 'salary', date: d(2026, 8, 30), countInProjection: false);
    });
    await openEvents(tester);
    expect(find.text('−RM250.00 · 20/07/2026'), findsOneWidget);
    expect(find.text('+RM500.00 · 30/08/2026 · not counted'), findsOneWidget);
  });

  testWidgets('Done takes an event out of the list', (tester) async {
    final world = await pumpApp(tester, seed: (w) {
      w.addEvent(name: 'Car service', isIncome: false, amount: 25000, categoryKey: 'transport', date: d(2026, 7, 20));
    });
    await openEvents(tester);
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(world.events.single.done, isTrue);
    expect(find.text('Car service'), findsNothing);
  });

  testWidgets('a new event needs every field', (tester) async {
    final world = await pumpApp(tester);
    await openEvents(tester);
    await tester.tap(find.text('Add an event'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save event'));
    await tester.tap(find.text('Save event'));
    await tester.pumpAndSettle();
    expect(find.text('Give it a name'), findsOneWidget);
    expect(find.text('Pick when it happens'), findsOneWidget);
    expect(world.events, isEmpty);
  });
}
