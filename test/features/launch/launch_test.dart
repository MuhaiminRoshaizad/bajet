import 'package:bajet/features/launch/domain/launch_link.dart';
import 'package:bajet/features/ledger/domain/ledger_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/app_harness.dart';

void main() {
  test('links round-trip, and anything else is ignored', () {
    for (final link in [const LaunchLink.log(), const LaunchLink.log(favouriteId: 3)]) {
      expect(LaunchLink.parse(link.toUri()), link);
    }
    expect(LaunchLink.parse(Uri.parse('https://example.com/log')), isNull);
    expect(LaunchLink.parse(null), isNull);
  });

  testWidgets('a favourite shortcut opens the logger filled in, not logged', (tester) async {
    final world = await pumpApp(tester, seed: (w) => w.favourites.add(label: 'Lunch', categoryKey: 'food', amount: 800));
    world.home.launch(const LaunchLink.log(favouriteId: 1));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(FilledButton, 'Log RM8.00'), findsOneWidget);
    expect(world.entries, isEmpty);
  });

  testWidgets('the plain shortcut opens an empty logger', (tester) async {
    final world = await pumpApp(tester);
    world.home.launch(const LaunchLink.log());
    await tester.pumpAndSettle();
    expect(find.widgetWithText(FilledButton, 'Type the amount'), findsOneWidget);
  });

  testWidgets('shortcuts and the widget follow favourites and the week, without the balance', (tester) async {
    final world = await pumpApp(tester, seed: (w) {
      w.favourites.add(label: 'Lunch', categoryKey: 'food', amount: 800);
      w.add(EntryDraft(day: testToday, isIncome: false, amount: 1200, categoryKey: 'food'));
    });
    expect(world.home.shortcuts, [(1, 'Lunch')]);
    expect(world.home.widget!.weekLine, 'RM38.00 left this week');
    expect(world.home.widget!.favourites, [(1, 'Lunch')]);
  });
}
