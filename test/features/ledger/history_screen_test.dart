import 'package:bajet/features/accounts/domain/account_models.dart';
import 'package:bajet/features/ledger/domain/ledger_models.dart';
import 'package:bajet/features/plan/domain/plan_models.dart';
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

  testWidgets('editing an entry does not count it against the day twice', (tester) async {
    await pumpApp(tester, seed: (w) {
      w.saveRule(WeeklyRule(weekday: testToday.weekday, label: 'Weekday', type: DayType.spend, plannedSpend: 1000));
      w.add(EntryDraft(day: testToday, isIncome: false, amount: 570, categoryKey: 'food', label: 'Lunch'));
    });
    await openHistory(tester);

    await tester.tap(find.text('Lunch'));
    await tester.pumpAndSettle();
    expect(find.text("Within today's plan"), findsOneWidget);
  });

  testWidgets('an entry from months back is judged against everything spent that day', (tester) async {
    final old = DateTime.utc(testToday.year, testToday.month, testToday.day - 90);
    await pumpApp(tester, seed: (w) {
      w.saveRule(WeeklyRule(weekday: old.weekday, label: 'Weekday', type: DayType.spend, plannedSpend: 2000));
      w.add(EntryDraft(day: old, isIncome: false, amount: 2000, categoryKey: 'food', label: 'Book'));
      w.add(EntryDraft(day: old, isIncome: false, amount: 500, categoryKey: 'food', label: 'Snack'));
      // Today lists only recent entries, and offers History once it has one.
      w.add(EntryDraft(day: testToday, isIncome: false, amount: 450, categoryKey: 'food', label: 'Coffee'));
    });
    await openHistory(tester);
    await tester.scrollUntilVisible(find.text('Snack'), 200);
    await tester.tap(find.text('Snack'));
    await tester.pumpAndSettle();
    expect(find.text("RM5.00 over that day's RM20.00 plan"), findsOneWidget);
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

  testWidgets('an entry can be deleted from its edit sheet too, with undo', (tester) async {
    final world = await pumpApp(tester, seed: seedTwoDays);
    await openHistory(tester);
    final before = world.entries.length;
    await tester.tap(find.text('Coffee'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Delete entry'));
    await tester.tap(find.text('Delete entry'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(world.entries.length, before - 1);
    expect(find.text('Save changes'), findsNothing);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(world.entries.length, before);
  });

  void seedWithMove(FakeWorld w) {
    seedTwoDays(w);
    w.addAccount(const AccountDraft(kind: AccountKind.cash, name: 'Cash', balance: 0, look: CardLook(color: 0xFF6B3F24, finish: CardFinish.leather)));
    w.transfer(fromId: 1, toId: 2, amount: 5000, day: testToday);
  }

  testWidgets("money moved shows in its own row on its day, never in the day's spending", (tester) async {
    await pumpApp(tester, seed: seedWithMove);
    await openHistory(tester);

    expect(find.text('Main account → Cash'), findsOneWidget);
    expect(find.text('RM50.00'), findsOneWidget);
    expect(find.textContaining('Moved, not spent'), findsOneWidget);
    // Today's heading still totals only the coffee.
    expect(find.text('−RM4.50'), findsNWidgets(2));
  });

  testWidgets('a move can be deleted from History, with undo', (tester) async {
    final world = await pumpApp(tester, seed: seedWithMove);
    await openHistory(tester);

    await tester.drag(find.text('Main account → Cash'), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(find.text('Delete this move?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(world.transferCount, 0);
    expect(find.text('Main account → Cash'), findsNothing);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(world.transferCount, 1);
    expect(find.text('Main account → Cash'), findsOneWidget);
  });
}
