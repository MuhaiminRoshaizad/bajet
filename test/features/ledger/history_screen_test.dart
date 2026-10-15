import 'package:bajet/features/ledger/domain/ledger_models.dart';
import 'package:bajet/core/navigation/routes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/fake_repositories.dart';

DateTime d(int y, int m, int day) => DateTime.utc(y, m, day);

void seedTwoDays(FakeWorld w) {
  w.add(EntryDraft(day: d(2026, 6, 29), isIncome: false, amount: 1200, categoryKey: 'transport'));
  w.add(EntryDraft(day: testToday, isIncome: false, amount: 450, categoryKey: 'food', label: 'Coffee'));
}

Future<void> openHistory(WidgetTester tester) async {
  await tester.ensureVisible(find.text('See all'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('See all'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('groups entries by day, newest first, with each day\'s spending', (tester) async {
    await pumpApp(tester, seed: seedTwoDays);
    await openHistory(tester);

    expect(find.text('History'), findsOneWidget);
    final today = tester.getTopLeft(find.descendant(of: find.byType(ListView), matching: find.text('Today'))).dy;
    final monday = tester.getTopLeft(find.text('Mon 29/06/2026')).dy;
    expect(today, lessThan(monday));
    expect(find.text('−RM4.50'), findsWidgets);
    expect(find.text('−RM12.00'), findsWidgets);
  });

  testWidgets('tapping an entry edits it in the log sheet', (tester) async {
    final world = await pumpApp(tester, seed: seedTwoDays);
    await openHistory(tester);

    await tester.tap(find.text('Coffee'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(FilledButton, 'Save changes'), findsOneWidget);

    await tester.enterText(find.byKey(const ValueKey('amount')), '4500');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Save changes'));
    await tester.pumpAndSettle();

    expect(world.entries.firstWhere((e) => e.label == 'Coffee').amount, 4500);
    expect(find.text('Saved changes'), findsOneWidget);
  });

  testWidgets('swiping asks before deleting, and Keep leaves the entry', (tester) async {
    final world = await pumpApp(tester, seed: seedTwoDays);
    await openHistory(tester);

    await tester.drag(find.text('Coffee'), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(find.text('Delete this entry?'), findsOneWidget);

    await tester.tap(find.text('Keep'));
    await tester.pumpAndSettle();
    expect(world.entries, hasLength(2));
    expect(find.text('Coffee'), findsOneWidget);
  });

  testWidgets('a confirmed delete can be undone', (tester) async {
    final world = await pumpApp(tester, seed: seedTwoDays);
    await openHistory(tester);

    await tester.drag(find.text('Coffee'), const Offset(-500, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(world.entries, hasLength(1));

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(world.entries.map((e) => e.label), contains('Coffee'));
  });

  testWidgets('See all is hidden until something has been logged', (tester) async {
    await pumpApp(tester);
    expect(find.text('See all'), findsNothing);
  });

  testWidgets('with nothing logged it says so in the middle and offers to log', (tester) async {
    await pumpApp(tester);
    // See all appears only once something is logged, so open History directly,
    // as it is after the last entry is deleted.
    GoRouter.of(tester.element(find.byType(Scaffold).first)).push(Routes.history);
    await tester.pumpAndSettle();
    expect(find.text('Nothing logged yet'), findsOneWidget);
    expect(tester.getCenter(find.text('Nothing logged yet')).dy, inInclusiveRange(250, 450));

    await tester.tap(find.text('Log a spend'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(FilledButton, 'Type the amount'), findsOneWidget);
  });
}
