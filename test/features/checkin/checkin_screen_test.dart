import 'package:bajet/features/accounts/domain/account_models.dart';
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
}
