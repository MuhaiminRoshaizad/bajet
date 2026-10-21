import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/app_harness.dart';

Future<void> openFavourites(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Settings'));
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text('Favourites'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Favourites'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('adds a favourite with a name, amount and category', (tester) async {
    final world = await pumpApp(tester);
    await openFavourites(tester);
    await tester.tap(find.text('Add a favourite'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'Name'), 'Coffee');
    await tester.enterText(find.widgetWithText(TextFormField, 'Usual amount'), '450');
    await tester.tap(find.widgetWithText(ChoiceChip, 'Food'));
    await tester.tap(find.text('Save favourite'));
    await tester.pumpAndSettle();

    final f = world.favourites.all.single;
    expect((f.label, f.amount, f.categoryKey), ('Coffee', 450, 'food'));
    expect(find.text('Coffee'), findsOneWidget);
  });

  testWidgets('saving without a category says so', (tester) async {
    final world = await pumpApp(tester);
    await openFavourites(tester);
    await tester.tap(find.text('Add a favourite'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Name'), 'Coffee');
    await tester.enterText(find.widgetWithText(TextFormField, 'Usual amount'), '450');
    await tester.tap(find.text('Save favourite'));
    await tester.pumpAndSettle();
    expect(find.text('Pick a category'), findsOneWidget);
    expect(world.favourites.all, isEmpty);
  });

  testWidgets('removing asks first and can be undone', (tester) async {
    final world = await pumpApp(tester, seed: (w) => w.favourites.add(label: 'Coffee', categoryKey: 'food', amount: 450));
    await openFavourites(tester);
    await tester.tap(find.text('Coffee'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove favourite'));
    await tester.pumpAndSettle();
    expect(find.text('Remove Coffee?'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Remove'));
    await tester.pumpAndSettle();
    expect(world.favourites.all, isEmpty);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(world.favourites.all.single.label, 'Coffee');
  });

  testWidgets('the logger links to favourites when there are none', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byKey(const ValueKey('add')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Set up favourites for things you buy often'));
    await tester.pumpAndSettle();
    expect(find.text('Add a favourite'), findsOneWidget);
  });
}
