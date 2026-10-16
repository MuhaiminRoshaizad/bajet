import 'package:bajet/features/launch/domain/launch_link.dart';
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

  testWidgets('the shortcuts follow the favourites', (tester) async {
    final world = await pumpApp(tester, seed: (w) => w.favourites.add(label: 'Lunch', categoryKey: 'food', amount: 800));
    expect(world.home.shortcuts, [(1, 'Lunch')]);
  });
}
