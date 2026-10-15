import 'package:bajet/features/accounts/domain/account_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/app_harness.dart';

DateTime d(int y, int m, int day) => DateTime.utc(y, m, day);

Future<void> openRecurring(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Settings'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Bills and income'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('lists items with their amount and next due date', (tester) async {
    await pumpApp(tester, seed: (w) => w.addRecurring(name: 'Rent', isIncome: false, amount: 50000, categoryKey: 'bills', nextDue: d(2026, 8, 1)));
    await openRecurring(tester);
    expect(find.text('Rent'), findsOneWidget);
    expect(find.text('Next 01/08/2026'), findsOneWidget);
    expect(find.text('−RM500.00'), findsOneWidget);
  });

  testWidgets('income and bills are listed apart, each with its monthly total', (tester) async {
    await pumpApp(tester, seed: (w) {
      w.addRecurring(name: 'Salary', isIncome: true, amount: 300000, categoryKey: 'salary', nextDue: d(2026, 7, 25));
      w.addRecurring(name: 'Rent', isIncome: false, amount: 90000, categoryKey: 'bills', nextDue: d(2026, 8, 1));
      w.addRecurring(name: 'Phone', isIncome: false, amount: 4800, categoryKey: 'bills', nextDue: d(2026, 8, 10));
    });
    await openRecurring(tester);
    expect(find.text('+RM3,000.00 a month'), findsOneWidget);
    expect(find.text('−RM948.00 a month'), findsOneWidget);
    expect(find.text('RM2,052.00 a month'), findsOneWidget);
    // Income comes first, then bills.
    expect(tester.getTopLeft(find.text('Income')).dy, lessThan(tester.getTopLeft(find.text('Bills')).dy));
    expect(tester.getTopLeft(find.text('Salary')).dy, lessThan(tester.getTopLeft(find.text('Bills')).dy));
  });

  testWidgets('an item that moves around shows its window', (tester) async {
    await pumpApp(tester, seed: (w) => w.addRecurring(name: 'Salary', isIncome: true, amount: 300000, categoryKey: 'salary', nextDue: d(2026, 7, 25), windowDays: 3));
    await openRecurring(tester);
    expect(find.text('Next 25/07 to 28/07/2026'), findsOneWidget);
  });

  testWidgets('pausing is done in the edit sheet, and a paused bill leaves the total', (tester) async {
    final world = await pumpApp(tester, seed: (w) => w.addRecurring(name: 'Gym', isIncome: false, amount: 9000, categoryKey: 'bills', nextDue: d(2026, 8, 3)));
    await openRecurring(tester);
    expect(find.byType(Switch), findsNothing);
    await tester.tap(find.text('Gym'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Counted each month'));
    await tester.tap(find.text('Counted each month'));
    await tester.pump();
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Save'));
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(world.recurring.single.active, isFalse);
    expect(find.text('Paused'), findsOneWidget);
    expect(find.text('−RM0.00 a month'), findsOneWidget);
  });

  testWidgets('saving a new item asks for everything it needs', (tester) async {
    final world = await pumpApp(tester);
    await openRecurring(tester);
    await tester.tap(find.text('Add a bill or income'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Save'));
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(find.text('Give it a name'), findsOneWidget);
    expect(find.text('Enter the amount'), findsOneWidget);
    expect(find.text('Pick a category'), findsWidgets);
    expect(find.text('Pick when it is next due'), findsOneWidget);
    expect(world.recurring, isEmpty);
  });

  testWidgets('income offers income categories only', (tester) async {
    await pumpApp(tester);
    await openRecurring(tester);
    await tester.tap(find.text('Add a bill or income'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Income').last);
    await tester.pumpAndSettle();
    expect(find.widgetWithText(ChoiceChip, 'Salary'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Bills'), findsNothing);
  });

  testWidgets('pay that changes day is saved with its earliest and latest day', (tester) async {
    final world = await pumpApp(tester);
    // The range picker's own header sets both dates in one row; the test
    // font draws every glyph as a full square, so give it a wider screen.
    tester.view.physicalSize = const Size(1440, 2340);
    await tester.pumpAndSettle();
    await openRecurring(tester);
    await tester.tap(find.text('Add a bill or income'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Income').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Name'), 'Salary');
    await tester.enterText(find.widgetWithText(TextFormField, 'Amount each month'), '300000');
    await tester.tap(find.widgetWithText(ChoiceChip, 'Salary'));
    await tester.pump();
    await tester.ensureVisible(find.text('The day changes each month'));
    await tester.tap(find.text('The day changes each month'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Runway counts it on the latest'), findsOneWidget);

    await tester.tap(find.text('Pick the earliest and latest day'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('25').first);
    await tester.pump();
    await tester.tap(find.text('28').first);
    await tester.pump();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.text('Next between 25/07 to 28/07/2026'), findsOneWidget);

    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Save'));
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
    final salary = world.recurring.single;
    expect((salary.isIncome, salary.nextDue, salary.windowDays), (true, d(2026, 7, 25), 3));
  });

  testWidgets('tapping an item edits it, so a fixed payday can become a window', (tester) async {
    final world = await pumpApp(tester, seed: (w) => w.addRecurring(name: 'Salary', isIncome: true, amount: 300000, categoryKey: 'salary', nextDue: d(2026, 7, 25)));
    tester.view.physicalSize = const Size(1440, 2340);
    await openRecurring(tester);
    await tester.tap(find.text('Salary'));
    await tester.pumpAndSettle();
    expect(find.text('Edit income'), findsOneWidget);
    expect(find.text('Bill'), findsNothing);
    expect(find.text('3,000.00'), findsOneWidget);

    await tester.ensureVisible(find.text('The day changes each month'));
    await tester.tap(find.text('The day changes each month'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pick the earliest and latest day'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('25').first);
    await tester.pump();
    await tester.tap(find.text('28').first);
    await tester.pump();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Save'));
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    final salary = world.recurring.single;
    expect((salary.name, salary.amount, salary.windowDays), ('Salary', 300000, 3));
    expect(find.text('Next 25/07 to 28/07/2026'), findsOneWidget);
  });

  testWidgets('deleting a bill asks first and can be undone', (tester) async {
    final world = await pumpApp(tester, seed: (w) => w.addRecurring(name: 'Gym', isIncome: false, amount: 9000, categoryKey: 'bills', nextDue: d(2026, 8, 3)));
    await openRecurring(tester);
    await tester.tap(find.text('Gym'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Delete bill'));
    await tester.tap(find.text('Delete bill'));
    await tester.pumpAndSettle();
    expect(find.text('Delete Gym?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(world.recurring, isEmpty);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(world.recurring.single.name, 'Gym');
  });

  testWidgets('with two accounts a bill says which one it is paid from', (tester) async {
    late int cash;
    final world = await pumpApp(tester, seed: (w) async {
      w.addRecurring(name: 'Rent', isIncome: false, amount: 50000, categoryKey: 'bills', nextDue: d(2026, 8, 1));
      cash = await w.addAccount(const AccountDraft(kind: AccountKind.cash, name: 'Cash', look: CardLook(color: 0xFF6B3F24, finish: CardFinish.leather)));
    });
    await openRecurring(tester);
    await tester.tap(find.text('Rent'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(ValueKey('Paid from-$cash')));
    await tester.tap(find.byKey(ValueKey('Paid from-$cash')));
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Save'));
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
    expect(world.recurring.single.accountId, cash);
  });
}
