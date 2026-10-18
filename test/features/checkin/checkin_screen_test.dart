import 'package:bajet/features/accounts/domain/account_models.dart';
import 'package:bajet/features/checkin/domain/checkin.dart';
import 'package:bajet/features/ledger/domain/ledger_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/app_harness.dart';

Future<void> openCheckin(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Settings'));
  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(find.text('Sunday check-in'), 200);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Sunday check-in'));
  await tester.pumpAndSettle();
}

Finder bankField() => find.widgetWithText(TextFormField, 'Bank app says');

void main() {
  testWidgets('a matching bank balance is confirmed', (tester) async {
    await pumpApp(tester);
    await openCheckin(tester);
    expect(find.text('RM1,500.00'), findsOneWidget);

    await tester.enterText(bankField(), '150000');
    await tester.pumpAndSettle();
    expect(find.text('Matches exactly'), findsOneWidget);
  });

  testWidgets('money missing from the bank can be logged as untracked', (tester) async {
    final world = await pumpApp(tester);
    await openCheckin(tester);
    await tester.enterText(bankField(), '148000');
    await tester.pumpAndSettle();
    expect(find.text('RM20.00 spent but not logged'), findsOneWidget);

    await tester.ensureVisible(find.text('Log RM20.00 as untracked'));
    await tester.tap(find.text('Log RM20.00 as untracked'));
    await tester.pumpAndSettle();

    final e = world.entries.single;
    expect((e.amount, e.categoryKey, e.isIncome), (2000, untrackedCategoryKey, false));
    expect(find.text('Matches exactly'), findsOneWidget);
  });

  testWidgets('extra money in the bank opens the logger as income, filled in', (tester) async {
    await pumpApp(tester);
    await openCheckin(tester);
    await tester.enterText(bankField(), '151000');
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Log the income'));
    await tester.tap(find.text('Log the income'));
    await tester.pumpAndSettle();
    expect(find.text('RM10.00'), findsWidgets);
    expect(find.bySemanticsLabel('Salary'), findsOneWidget);
  });

  testWidgets('Today does not offer the check-in midweek', (tester) async {
    await pumpApp(tester);
    expect(find.text('Sunday check-in'), findsNothing);
  });

  testWidgets('with several accounts each is checked on its own, and a gap is logged to that account', (tester) async {
    late int cash;
    final world = await pumpApp(tester, seed: (w) async {
      cash = await w.addAccount(const AccountDraft(kind: AccountKind.cash, name: 'Cash', balance: 8450, look: CardLook(color: 0xFF6B3F24, finish: CardFinish.leather)));
    });
    await openCheckin(tester);
    expect(find.text('Does each account match?'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextFormField, 'Counted in the wallet'), '8000');
    await tester.pumpAndSettle();
    expect(find.text('RM4.50 spent but not logged'), findsOneWidget);

    await tester.ensureVisible(find.text('Log RM4.50 as untracked'));
    await tester.tap(find.text('Log RM4.50 as untracked'));
    await tester.pumpAndSettle();
    final e = world.entries.single;
    expect((e.amount, e.accountId), (450, cash));
    expect(world.accounts.firstWhere((a) => a.id == cash).balance, 8000);
  });

  Future<void> finish(WidgetTester tester) async {
    await tester.ensureVisible(find.text('Finish check-in'));
    await tester.tap(find.text('Finish check-in'));
    await tester.pumpAndSettle();
  }

  testWidgets("finishing saves the check-in with next week's target", (tester) async {
    final world = await pumpApp(tester);
    await openCheckin(tester);
    await tester.enterText(bankField(), '150000');
    await tester.pumpAndSettle();
    await finish(tester);

    final c = world.checkins.saved.single;
    expect((c.checkedOn, c.balance, c.matched, c.untracked, c.startingAdjustment), (testToday, 150000, true, 0, 0));
    // The demo rhythm plans nothing, so the plan expects the same balance.
    expect(c.nextTarget, 150000);
    expect(find.text('Update check-in'), findsOneWidget);
    expect(find.text('Saved. Next week is judged against RM1,500.00 on Wed 08/07.'), findsOneWidget);
  });

  testWidgets('a check-in finished without comparing every account is not a match', (tester) async {
    final world = await pumpApp(tester);
    await openCheckin(tester);
    await finish(tester);
    expect(world.checkins.saved.single.matched, isFalse);
  });

  testWidgets('a gap at the first check-in is a starting adjustment, not untracked', (tester) async {
    final world = await pumpApp(tester);
    await openCheckin(tester);
    await tester.enterText(bankField(), '148000');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Log RM20.00 as untracked'));
    await tester.tap(find.text('Log RM20.00 as untracked'));
    await tester.pumpAndSettle();
    expect(find.text('Logged RM20.00 as a starting adjustment'), findsOneWidget);
    expect(world.entries.single.label, 'Starting adjustment');

    await finish(tester);
    final c = world.checkins.saved.single;
    expect((c.matched, c.startingAdjustment, c.untracked), (true, 2000, 0));
  });

  testWidgets('after an earlier check-in a gap is untracked', (tester) async {
    final world = await pumpApp(tester, seed: (w) {
      w.checkins.save(Checkin(checkedOn: DateTime.utc(2026, 6, 24), balance: 150000, matched: true, allowanceSpent: 0, nextTarget: 150000));
    });
    await openCheckin(tester);
    await tester.enterText(bankField(), '148000');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Log RM20.00 as untracked'));
    await tester.tap(find.text('Log RM20.00 as untracked'));
    await tester.pumpAndSettle();
    expect(world.entries.single.label, 'Untracked');

    await finish(tester);
    final c = world.checkins.saved.firstWhere((c) => c.checkedOn == testToday);
    expect((c.startingAdjustment, c.untracked), (0, 2000));
  });
}
