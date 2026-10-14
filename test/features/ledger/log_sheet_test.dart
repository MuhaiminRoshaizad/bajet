import 'package:bajet/features/ledger/domain/ledger_models.dart';
import 'package:bajet/features/plan/domain/plan_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/app_harness.dart';

Future<void> openLogger(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('add')));
  await tester.pumpAndSettle();
}

Future<void> typeKeys(WidgetTester tester, String keys) async {
  for (final k in keys.split('')) {
    final key = find.descendant(of: find.byType(GridView), matching: find.text(k)).last;
    await tester.ensureVisible(key);
    await tester.tap(key);
    await tester.pump();
  }
}

void main() {
  testWidgets('the log button stays disabled until amount and category are set', (tester) async {
    await pumpApp(tester);
    await openLogger(tester);

    expect(find.widgetWithText(FilledButton, 'Type the amount'), findsOneWidget);
    expect(tester.widget<FilledButton>(find.byType(FilledButton).last).onPressed, isNull);

    await typeKeys(tester, '450');
    expect(find.text('RM4.50'), findsWidgets);
    expect(find.widgetWithText(FilledButton, 'Pick a category'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Food'));
    await tester.pump();
    expect(find.widgetWithText(FilledButton, 'Log RM4.50'), findsOneWidget);
  });

  testWidgets('logging saves the entry, closes the sheet and offers undo', (tester) async {
    final world = await pumpApp(tester);
    await openLogger(tester);
    await typeKeys(tester, '1250');
    await tester.tap(find.bySemanticsLabel('Transport'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Log RM12.50'));
    await tester.pumpAndSettle();

    expect(world.entries.single.amount, 1250);
    expect(world.entries.single.categoryKey, 'transport');
    expect(world.entries.single.day, testToday);
    expect(find.text('Logged Transport RM12.50'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(world.entries, isEmpty);
  });

  testWidgets('a favourite fills the logger but saves nothing on its own', (tester) async {
    final world = await pumpApp(tester, seed: (w) => w.favourites.add(label: 'Coffee', categoryKey: 'food', amount: 450));
    await openLogger(tester);

    await tester.tap(find.bySemanticsLabel('Fill in Coffee, RM4.50'));
    await tester.pump();
    expect(world.entries, isEmpty);
    expect(find.widgetWithText(FilledButton, 'Log RM4.50'), findsOneWidget);

    // The amount stays editable after a favourite fills it in.
    await typeKeys(tester, '0');
    expect(find.widgetWithText(FilledButton, 'Log RM45.00'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Log RM45.00'));
    await tester.pumpAndSettle();
    expect((world.entries.single.label, world.entries.single.amount), ('Coffee', 4500));
  });

  testWidgets('income shows income categories and no favourites', (tester) async {
    await pumpApp(tester, seed: (w) => w.favourites.add(label: 'Coffee', categoryKey: 'food', amount: 450));
    await openLogger(tester);
    await tester.tap(find.text('Income'));
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Salary'), findsOneWidget);
    expect(find.bySemanticsLabel('Food'), findsNothing);
    expect(find.text('Favourites'), findsNothing);
  });

  testWidgets('warns when a spend goes over the day\'s plan', (tester) async {
    await pumpApp(tester, seed: (w) => w.saveRule(const WeeklyRule(weekday: 3, label: 'Weekday', type: DayType.spend, plannedSpend: 800)));
    await openLogger(tester);
    await typeKeys(tester, '1000');
    await tester.tap(find.bySemanticsLabel('Food'));
    await tester.pump();
    expect(find.text("RM2.00 over today's RM8.00 plan"), findsOneWidget);
  });

  testWidgets('the keypad stays in view, and steps aside while the keyboard is up', (tester) async {
    await pumpApp(tester);
    await openLogger(tester);
    expect(tester.getRect(find.text('9')).bottom, lessThan(780));

    tester.view.viewInsets = const FakeViewPadding(bottom: 900);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    expect(find.text('9'), findsNothing);
  });

  testWidgets('a receipt can be attached from the gallery and is saved with the entry', (tester) async {
    final world = await pumpApp(tester);
    await openLogger(tester);
    await typeKeys(tester, '1250');
    await tester.tap(find.bySemanticsLabel('Food'));
    await tester.pump();

    await tester.ensureVisible(find.text('Attach a receipt (optional)'));
    await tester.tap(find.text('Attach a receipt (optional)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose a photo or screenshot'));
    await tester.pumpAndSettle();
    expect(find.text('Receipt attached'), findsOneWidget);

    await tester.tap(find.text('Log RM12.50'));
    await tester.pumpAndSettle();
    expect(world.entries.single.receipt, 'receipt-1.jpg');
    expect(find.bySemanticsLabel(RegExp('has a receipt')), findsOneWidget);
  });

  testWidgets('an attached receipt can be taken off before saving', (tester) async {
    final world = await pumpApp(tester);
    await openLogger(tester);
    await typeKeys(tester, '500');
    await tester.tap(find.bySemanticsLabel('Food'));
    await tester.pump();
    await tester.ensureVisible(find.text('Attach a receipt (optional)'));
    await tester.tap(find.text('Attach a receipt (optional)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Take a photo'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Remove receipt'));
    await tester.pump();
    await tester.tap(find.text('Log RM5.00'));
    await tester.pumpAndSettle();
    expect(world.entries.single.receipt, isNull);
  });

  testWidgets('at launch, receipts no entry refers to are cleared out', (tester) async {
    final world = await pumpApp(tester, seed: (w) {
      w.add(EntryDraft(day: testToday, isIncome: false, amount: 800, categoryKey: 'food', receipt: 'kept.jpg'));
      w.add(EntryDraft(day: testToday, isIncome: false, amount: 300, categoryKey: 'food'));
    });
    expect(world.receipts.kept, {'kept.jpg'});
  });
}
