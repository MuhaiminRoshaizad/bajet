import 'package:bajet/features/accounts/domain/account_models.dart';
import 'package:bajet/features/accounts/presentation/account_stack.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/fake_repositories.dart';

void addCash(FakeWorld w) => w.addAccount(const AccountDraft(kind: AccountKind.cash, name: 'Cash', balance: 8450, look: CardLook(color: 0xFF6B3F24, finish: CardFinish.leather)));

Future<void> openMove(WidgetTester tester) async {
  await tester.tap(find.byType(AccountStack));
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text('Move money'));
  await tester.tap(find.text('Move money'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('moving money changes two balances, never the total, the week or the entries', (tester) async {
    final world = await pumpApp(tester, seed: addCash);
    await openMove(tester);
    await tester.enterText(find.widgetWithText(TextFormField, 'Amount'), '5000');
    await tester.pumpAndSettle();
    expect(find.textContaining('→ RM1,450.00', findRichText: true), findsOneWidget); // Main account after
    expect(find.textContaining('→ RM134.50', findRichText: true), findsOneWidget); // Cash after

    await tester.tap(find.text('Move RM50.00'));
    await tester.pumpAndSettle();
    expect({for (final a in world.accounts) a.name: a.balance}, {'Main account': 145000, 'Cash': 13450});
    expect(world.entries, isEmpty);
    expect(find.text('Moved RM50.00 from Main account to Cash').hitTestable(), findsOneWidget);

    await tester.tap(find.text('Undo').hitTestable());
    await tester.pumpAndSettle();
    expect(world.transferCount, 0);
  });

  testWidgets('nothing moves without an amount, and an account cannot move money to itself', (tester) async {
    await pumpApp(tester, seed: addCash);
    await openMove(tester);
    final button = tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Enter an amount to move'));
    expect(button.onPressed, isNull);
    final toMain = tester.widget<ChoiceChip>(find.byKey(const ValueKey('To-1')));
    expect(toMain.onSelected, isNull);
  });

  testWidgets('with one account there is nowhere to move money to', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byType(AccountStack));
    await tester.pumpAndSettle();
    expect(find.text('Move money'), findsNothing);
  });
}
