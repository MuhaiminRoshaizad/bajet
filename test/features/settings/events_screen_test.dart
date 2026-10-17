import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bajet/features/ledger/domain/ledger_models.dart';

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

  testWidgets('tapping an event edits it, and keeps its category', (tester) async {
    final world = await pumpApp(tester, seed: (w) => w.addEvent(name: 'Car service', isIncome: false, amount: 25000, categoryKey: 'transport', date: d(2026, 7, 20)));
    await openEvents(tester);
    await tester.tap(find.text('Car service'));
    await tester.pumpAndSettle();
    expect(find.text('Edit event'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextFormField, 'Amount'), '30000');
    await tester.ensureVisible(find.text('Save event'));
    await tester.tap(find.text('Save event'));
    await tester.pumpAndSettle();
    final e = world.events.single;
    expect((e.amount, e.categoryKey, e.date), (30000, 'transport', d(2026, 7, 20)));
  });

  testWidgets('deleting an event asks first and can be undone', (tester) async {
    final world = await pumpApp(tester, seed: (w) => w.addEvent(name: 'Car service', isIncome: false, amount: 25000, categoryKey: 'transport', date: d(2026, 7, 20)));
    await openEvents(tester);
    await tester.tap(find.text('Car service'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Delete event'));
    await tester.tap(find.text('Delete event'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(world.events, isEmpty);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(world.events.single.name, 'Car service');
  });

  testWidgets('a birthday can be added as yearly, and Done moves it to next year', (tester) async {
    final world = await pumpApp(tester, seed: (w) => w.addEvent(name: 'Birthday', isIncome: false, amount: 10000, categoryKey: 'gifts', date: d(2026, 10, 30)));
    await openEvents(tester);
    await tester.tap(find.text('Birthday'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Every year'));
    await tester.tap(find.text('Every year'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Comes back on this date each year'), findsOneWidget);
    await tester.ensureVisible(find.text('Save event'));
    await tester.tap(find.text('Save event'));
    await tester.pumpAndSettle();
    expect(find.text('−RM100.00 · 30/10/2026 · every year'), findsOneWidget);

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(world.events.single.date, d(2027, 10, 30));
    expect(find.text('−RM100.00 · 30/10/2027 · every year'), findsOneWidget);
  });

  testWidgets('an event shows how much of its budget is spent', (tester) async {
    await pumpApp(tester, seed: (w) {
      w.addEvent(name: 'Birthday', isIncome: false, amount: 10000, categoryKey: 'gifts', date: d(2026, 7, 20));
      w.add(EntryDraft(day: testToday, isIncome: false, amount: 7300, categoryKey: 'food', event: EventLink(w.events.single.id, d(2026, 7, 20))));
    });
    await openEvents(tester);
    expect(find.text('RM73.00 of RM100.00 spent · 20/07/2026'), findsOneWidget);
  });

  testWidgets('the plan switch explains itself for an expense and an income, and the info opens without flipping it', (tester) async {
    await pumpApp(tester);
    await openEvents(tester);
    await tester.tap(find.text('Add an event'));
    await tester.pumpAndSettle();
    expect(find.text('Plan for it'), findsOneWidget);
    expect(find.textContaining('On if it will happen'), findsOneWidget);

    await tester.tap(find.text('Income'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Off if it might not come'), findsOneWidget);

    bool on() => tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value;
    expect(on(), isTrue);
    await tester.ensureVisible(find.byTooltip('What does Plan for it mean?'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('What does Plan for it mean?'));
    await tester.pumpAndSettle();
    expect(find.text('How a planned event works'), findsOneWidget);
    await tester.ensureVisible(find.text('Got it'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();
    expect(find.text('How a planned event works'), findsNothing);
    expect(on(), isTrue);
  });

  testWidgets('the date of an event already passed can still be changed', (tester) async {
    await pumpApp(tester, seed: (w) => w.addEvent(name: 'Car service', isIncome: false, amount: 25000, categoryKey: 'transport', date: d(2026, 6, 20)));
    await openEvents(tester);
    await tester.tap(find.text('Car service'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('20/06/2026'));
    await tester.tap(find.text('20/06/2026'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('When'), findsOneWidget, reason: 'the calendar is open');
  });
}
