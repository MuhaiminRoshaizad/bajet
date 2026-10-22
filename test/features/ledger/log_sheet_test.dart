import 'package:bajet/features/accounts/domain/account_models.dart';
import 'package:bajet/features/ledger/domain/ledger_models.dart';
import 'package:bajet/features/plan/domain/plan_models.dart';
import 'package:bajet/features/plan/domain/plan_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/app_harness.dart';

Future<void> openLogger(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('add')));
  await tester.pumpAndSettle();
}

final amountField = find.byKey(const ValueKey('amount'));
final receiptTile = find.byKey(const ValueKey('receipt-tile'));

/// Types [keys] on the number pad after whatever the amount already holds,
/// as the user does: each digit fills in from the right.
Future<void> typeKeys(WidgetTester tester, String keys) async {
  final held = tester.widget<TextField>(amountField).controller!.text.replaceAll(RegExp(r'\D'), '');
  await tester.enterText(amountField, held + keys);
  await tester.pump();
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

  testWidgets("a spend starts as its category's kind, and a tap makes this one a need", (tester) async {
    final world = await pumpApp(tester);
    await openLogger(tester);
    await typeKeys(tester, '4500');
    ChoiceChip chip(SpendKind k) => tester.widget<ChoiceChip>(find.byKey(ValueKey('kind-${k.name}')));
    await tester.tap(find.bySemanticsLabel('Family'));
    await tester.pumpAndSettle();
    expect(chip(SpendKind.need).selected, isTrue, reason: 'Family starts as a need');
    expect(find.text('A need: bought anyway or asked for, so it stays out of your RM50.'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Personal'));
    await tester.pumpAndSettle();
    expect(chip(SpendKind.want).selected, isTrue);
    await tester.ensureVisible(find.byKey(const ValueKey('kind-need')));
    await tester.tap(find.byKey(const ValueKey('kind-need')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Log RM45.00'));
    await settleUnderBar(tester);
    expect(world.entries.single.spendKind, SpendKind.need);
    expect(find.text('Logged Personal RM45.00 as a need'), findsOneWidget);
  });

  testWidgets('income, a fixed category and a bill ask no kind', (tester) async {
    final world = await pumpApp(tester, seed: (w) => w.addRecurring(name: 'Phone', isIncome: false, amount: 5000, categoryKey: 'personal', nextDue: DateTime.utc(2026, 7, 1)));
    await openLogger(tester);
    expect(find.text('What kind?'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Bills'));
    await tester.pumpAndSettle();
    expect(find.text('What kind?'), findsNothing);
    await tester.tap(find.bySemanticsLabel('Personal'));
    await tester.pumpAndSettle();
    final bill = find.byKey(ValueKey('due-bill-${world.recurring.single.id}'));
    await tester.ensureVisible(bill);
    await tester.tap(bill);
    await tester.pumpAndSettle();
    expect(find.text('What kind?'), findsNothing);
    await tester.tap(find.text('Income'));
    await tester.pumpAndSettle();
    expect(find.text('What kind?'), findsNothing);
  });

  testWidgets('logging saves the entry, closes the sheet and offers undo', (tester) async {
    final world = await pumpApp(tester);
    await openLogger(tester);
    await typeKeys(tester, '1250');
    await tester.tap(find.bySemanticsLabel('Transport'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Log RM12.50'));
    await settleUnderBar(tester);

    expect(world.entries.single.amount, 1250);
    expect(world.entries.single.categoryKey, 'transport');
    expect(world.entries.single.day, testToday);
    expect(find.text('Logged Transport RM12.50'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await settleUnderBar(tester);
    expect(world.entries, isEmpty);
  });

  testWidgets('a note is kept as typed, with no capital forced on it', (tester) async {
    final world = await pumpApp(tester);
    await openLogger(tester);
    await typeKeys(tester, '800');
    await tester.tap(find.bySemanticsLabel('Food'));
    await tester.enterText(find.widgetWithText(TextField, 'Note (optional)'), 'makan');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Log RM8.00'));
    await tester.pumpAndSettle();
    expect(world.entries.single.note, 'makan');
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

  testWidgets('a new entry opens with the number pad down until the amount is tapped, then Log sits above it', (tester) async {
    await pumpApp(tester);
    await openLogger(tester);
    expect(tester.testTextInput.isVisible, isFalse, reason: 'the favourites and categories show first');
    await tester.tap(amountField);
    await tester.pump();
    expect(tester.widget<TextField>(amountField).keyboardType, TextInputType.number);
    expect(tester.testTextInput.isVisible, isTrue);

    // With the number pad taking the lower half, Log still sits above it.
    tester.view.viewInsets = const FakeViewPadding(bottom: 900);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    expect(tester.getRect(find.widgetWithText(FilledButton, 'Type the amount')).bottom, lessThanOrEqualTo(780 - 300));
  });

  testWidgets('digits fill the amount from the right and stray keys do nothing', (tester) async {
    await pumpApp(tester);
    await openLogger(tester);
    await tester.enterText(amountField, '5-7 0.');
    await tester.pump();
    expect(tester.widget<TextField>(amountField).controller!.text, 'RM5.70');
  });

  testWidgets('a receipt can be attached from the gallery and is saved with the entry', (tester) async {
    final world = await pumpApp(tester);
    await openLogger(tester);
    await typeKeys(tester, '1250');
    await tester.tap(find.bySemanticsLabel('Food'));
    await tester.pump();

    await tester.ensureVisible(receiptTile);
    await tester.tap(receiptTile);
    await tester.pumpAndSettle();
    expect(find.text('Add a receipt'), findsOneWidget);
    await tester.tap(find.text('Photos'));
    await tester.pumpAndSettle();
    expect(find.descendant(of: receiptTile, matching: find.text('Attached')), findsOneWidget);

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
    await tester.ensureVisible(receiptTile);
    await tester.tap(receiptTile);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Camera'));
    await tester.pumpAndSettle();

    await tester.tap(receiptTile);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove receipt'));
    await tester.pumpAndSettle();
    expect(find.descendant(of: receiptTile, matching: find.text('None')), findsOneWidget);
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

  testWidgets('the day is today unless another is picked from the calendar', (tester) async {
    final world = await pumpApp(tester, setUpDone: false, seed: (w) => w.saveSettings(PlanSettings(openingDate: DateTime.utc(2026, 6, 1), weeklyCap: 5000, buffer: 0)));
    await openLogger(tester);
    await typeKeys(tester, '500');
    await tester.tap(find.bySemanticsLabel('Food'));
    await tester.pump();

    // The bottom bar has a Today too, so find the day tile itself.
    final dayButton = find.byKey(const ValueKey('day-tile'));
    await tester.ensureVisible(dayButton);
    await tester.tap(dayButton);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Previous month'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('28'));
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.descendant(of: dayButton, matching: find.text('Sun 28/06')), findsOneWidget);

    await tester.tap(find.text('Log RM5.00'));
    await tester.pumpAndSettle();
    expect(world.entries.single.day, DateTime.utc(2026, 6, 28));
  });

  testWidgets('a day forgotten before setting up can be logged, and leaves the balance alone', (tester) async {
    // Set up on 01/07 with RM1,500.00, which was already after this lunch.
    final world = await pumpApp(tester);
    final before = world.accounts.single.balance;
    await openLogger(tester);
    await typeKeys(tester, '1200');
    await tester.tap(find.bySemanticsLabel('Food'));
    await tester.pump();
    expect(find.byKey(const ValueKey('before-opening')), findsNothing);

    final dayButton = find.byKey(const ValueKey('day-tile'));
    await tester.ensureVisible(dayButton);
    await tester.tap(dayButton);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Previous month'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('29'));
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.textContaining('This is before you set up bajet on 01/07/2026.'), findsOneWidget);

    await tester.tap(find.text('Log RM12.00'));
    await tester.pumpAndSettle();
    expect(world.entries.single.day, DateTime.utc(2026, 6, 29));
    expect(world.accounts.single.balance, before);
  });

  testWidgets('a spend can be for a nearby event, and counts against its budget', (tester) async {
    final world = await pumpApp(tester, seed: (w) {
      w.addEvent(name: 'Birthday', isIncome: false, amount: 10000, categoryKey: 'gifts', date: DateTime.utc(2026, 7, 10));
      // Two months off, so not offered.
      w.addEvent(name: 'Car service', isIncome: false, amount: 25000, categoryKey: 'transport', date: DateTime.utc(2026, 9, 1));
    });
    await openLogger(tester);
    await typeKeys(tester, '4500');
    await tester.tap(find.bySemanticsLabel('Food'));
    await tester.pump();

    final id = world.events.firstWhere((e) => e.name == 'Birthday').id;
    final birthday = find.byKey(ValueKey('due-event-$id'));
    await tester.ensureVisible(birthday);
    expect(find.text('RM100.00 left'), findsOneWidget);
    expect(find.textContaining('Car service'), findsNothing);
    await tester.tap(birthday);
    await tester.pump();
    expect(find.text('RM55.00 left of the Birthday budget'), findsOneWidget);

    await tester.tap(find.text('Log RM45.00'));
    await tester.pumpAndSettle();
    expect(world.entries.single.event, EventLink(id, DateTime.utc(2026, 7, 10)));
  });

  testWidgets('income offers income and income events, never spending events', (tester) async {
    await pumpApp(tester, seed: (w) {
      w.addEvent(name: 'Birthday', isIncome: false, amount: 10000, categoryKey: 'gifts', date: DateTime.utc(2026, 7, 10));
      w.addEvent(name: 'KWSP cash out', isIncome: true, amount: 30000, categoryKey: 'salary', date: DateTime.utc(2026, 7, 12));
      w.addRecurring(name: 'Gaji', isIncome: true, amount: 238445, categoryKey: 'salary', nextDue: DateTime.utc(2026, 7, 1));
    });
    await openLogger(tester);
    expect(find.text('For a bill or an event (optional)'), findsOneWidget);
    expect(find.text('Birthday'), findsOneWidget);
    await tester.tap(find.text('Income'));
    await tester.pumpAndSettle();
    expect(find.text('For your income or an event (optional)'), findsOneWidget);
    expect(find.text('Birthday'), findsNothing);
    final row = find.ancestor(of: find.text('For your income or an event (optional)'), matching: find.byType(Column)).first;
    expect(find.descendant(of: row, matching: find.text('Gaji')), findsOneWidget);
    // The row scrolls sideways, building the later tiles as they come in.
    await tester.scrollUntilVisible(find.text('KWSP cash out'), 200, scrollable: find.descendant(of: row, matching: find.byType(Scrollable)));
    expect(find.text('KWSP cash out'), findsOneWidget);
  });

  testWidgets('a bill outside the Bills category stays out of the allowance', (tester) async {
    final world = await pumpApp(tester, seed: (w) => w.addRecurring(name: 'Cat food', isIncome: false, amount: 1500, categoryKey: 'pets', nextDue: DateTime.utc(2026, 7, 1)));
    await openLogger(tester);
    final bill = find.byKey(ValueKey('due-bill-${world.recurring.single.id}'));
    await tester.ensureVisible(bill);
    await tester.tap(bill);
    await tester.pump();
    expect(find.textContaining("today's"), findsNothing, reason: 'a bill gets no plan hint');

    await tester.tap(find.text('Log RM15.00'));
    await settleUnderBar(tester);
    expect(world.entries.single.categoryKey, 'pets');
    expect(find.text('Spent RM0.00 of RM50'), findsOneWidget);
  });

  testWidgets('a bill picked on an empty sheet fills it in, and logging it pays that month; Undo puts it back', (tester) async {
    final world = await pumpApp(tester, seed: (w) => w.addRecurring(name: 'Claude Max 5x', isIncome: false, amount: 45099, categoryKey: 'bills', nextDue: DateTime.utc(2026, 7, 1)));
    await openLogger(tester);
    final bill = find.byKey(ValueKey('due-bill-${world.recurring.single.id}'));
    await tester.ensureVisible(bill);
    await tester.tap(bill);
    await tester.pump();
    expect(tester.widget<TextField>(amountField).controller!.text, 'RM450.99');
    expect(find.text('Type what was really paid; it counts instead of the planned amount.'), findsOneWidget);

    await tester.tap(find.text('Log RM450.99'));
    await settleUnderBar(tester);
    final paid = world.entries.single;
    expect((paid.amount, paid.categoryKey, paid.label, paid.billId), (45099, 'bills', 'Claude Max 5x', world.recurring.single.id));
    expect(world.recurring.single.nextDue, DateTime.utc(2026, 8, 1));
    expect(find.text('Paid Claude Max 5x RM450.99'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(world.entries, isEmpty);
    expect(world.recurring.single.nextDue, DateTime.utc(2026, 7, 1));
  });

  testWidgets('income received for Gaji counts the real amount typed, not the planned one', (tester) async {
    final world = await pumpApp(tester, seed: (w) => w.addRecurring(name: 'Gaji', isIncome: true, amount: 238445, categoryKey: 'salary', nextDue: DateTime.utc(2026, 7, 1)));
    await openLogger(tester);
    await tester.tap(find.text('Income'));
    await tester.pumpAndSettle();
    await typeKeys(tester, '261230');
    final gaji = find.byKey(ValueKey('due-bill-${world.recurring.single.id}'));
    await tester.ensureVisible(gaji);
    await tester.tap(gaji);
    await tester.pump();
    expect(tester.widget<TextField>(amountField).controller!.text, 'RM2,612.30', reason: 'what was typed stays');
    await tester.tap(find.text('Add RM2,612.30'));
    await settleUnderBar(tester);
    expect((world.entries.single.amount, world.recurring.single.nextDue), (261230, DateTime.utc(2026, 8, 1)));
    expect(find.text('Received Gaji RM2,612.30'), findsOneWidget);
  });

  testWidgets('income logged for an income event closes it with the real amount', (tester) async {
    final world = await pumpApp(tester, seed: (w) => w.addEvent(name: 'KWSP cash out', isIncome: true, amount: 30000, categoryKey: 'salary', date: DateTime.utc(2026, 7, 12)));
    await openLogger(tester);
    await tester.tap(find.text('Income'));
    await tester.pumpAndSettle();
    await typeKeys(tester, '35000');
    final kwsp = find.byKey(ValueKey('due-event-${world.events.single.id}'));
    await tester.ensureVisible(kwsp);
    await tester.tap(kwsp);
    await tester.pump();
    await tester.tap(find.text('Add RM350.00'));
    await settleUnderBar(tester);
    expect(world.entries.single.amount, 35000);
    expect(world.events.single.done, isTrue);
    expect(find.text('Received KWSP cash out RM350.00'), findsOneWidget);
  });

  testWidgets('an entry being edited offers events only, and keeps the bill it paid', (tester) async {
    final world = await pumpApp(tester, seed: (w) {
      w.addRecurring(name: 'Digi', isIncome: false, amount: 5000, categoryKey: 'bills', nextDue: DateTime.utc(2026, 8, 1));
      w.add(EntryDraft(day: DateTime.utc(2026, 7, 1), isIncome: false, amount: 5000, categoryKey: 'bills', label: 'Digi', billId: 1));
    });
    final entry = world.entries.single;
    final due = world.recurring.single.nextDue;
    await tester.ensureVisible(find.text('See all'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('See all'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Digi').last);
    await tester.pumpAndSettle();
    expect(find.text('Save changes'), findsOneWidget);
    expect(find.text('For a bill or an event (optional)'), findsNothing);
    await tester.tap(find.text('Save changes'));
    await settleUnderBar(tester);
    expect((world.entries.single.billId, world.recurring.single.nextDue), (entry.billId, due), reason: 'saving an edit moves no month');
  });

  testWidgets('a spend is paid from the account picked, and the next one starts there', (tester) async {
    late int cash;
    final world = await pumpApp(tester, seed: (w) async {
      cash = await w.addAccount(const AccountDraft(kind: AccountKind.cash, name: 'Cash', balance: 8450, look: CardLook(color: 0xFF6B3F24, finish: CardFinish.leather)));
    });
    await openLogger(tester);
    await typeKeys(tester, '570');
    await tester.tap(find.bySemanticsLabel('Food'));
    await tester.pump();
    await tester.ensureVisible(find.byKey(ValueKey('Paid from-$cash')));
    await tester.tap(find.byKey(ValueKey('Paid from-$cash')));
    await tester.pump();
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Log RM5.70'));
    await tester.tap(find.widgetWithText(FilledButton, 'Log RM5.70'));
    await tester.pumpAndSettle();
    expect(world.entries.single.accountId, cash);
    expect(world.accounts.firstWhere((a) => a.id == cash).balance, 8450 - 570);

    await openLogger(tester);
    await tester.ensureVisible(find.byKey(ValueKey('Paid from-$cash')));
    expect(tester.widget<ChoiceChip>(find.byKey(ValueKey('Paid from-$cash'))).selected, isTrue);
  });

  testWidgets('with one account the logger does not ask where the money went', (tester) async {
    await pumpApp(tester);
    await openLogger(tester);
    expect(find.text('Paid from'), findsNothing);
  });
}
