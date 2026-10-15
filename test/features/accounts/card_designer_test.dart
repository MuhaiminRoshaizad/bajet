import 'package:bajet/features/accounts/domain/account_models.dart';
import 'package:bajet/features/accounts/presentation/account_stack.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/app_harness.dart';

Future<void> openAccounts(WidgetTester tester) async {
  await tester.tap(find.byType(AccountStack));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets("the pencil on an account changes its card's colour, finish and nickname, not its balance", (tester) async {
    final world = await pumpApp(tester);
    await openAccounts(tester);
    await tester.tap(find.text('Main account').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Edit this card'));
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Black and gold'));
    await tester.tap(find.text('Gloss'));
    await tester.enterText(find.widgetWithText(TextField, 'Nickname (optional)'), 'Savings');
    await tester.ensureVisible(find.text('Save card'));
    await tester.tap(find.text('Save card'));
    await tester.pumpAndSettle();

    final main = world.accounts.single;
    expect((main.look, main.nickname, main.balance), (const CardLook(color: 0xFF151515, ink: 0xFFE6C674, finish: CardFinish.gloss), 'Savings', 150000));
  });

  testWidgets('cash is offered leathers and no finish', (tester) async {
    await pumpApp(tester, seed: (w) => w.addAccount(const AccountDraft(kind: AccountKind.cash, name: 'Cash', look: CardLook(color: 0xFF6B3F24, finish: CardFinish.leather))));
    await openAccounts(tester);
    await tester.tap(find.text('Cash').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Edit this card'));
    await tester.pumpAndSettle();
    expect(find.text('Leather'), findsOneWidget);
    expect(find.text('Brushed metal'), findsNothing);
  });

  testWidgets('tapping the total card restyles it, and Match the app puts it back', (tester) async {
    final world = await pumpApp(tester);
    await openAccounts(tester);
    await tester.tap(find.text('Total balance'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Champagne'));
    await tester.ensureVisible(find.text('Save total card'));
    await tester.tap(find.text('Save total card'));
    await tester.pumpAndSettle();
    expect(world.totalLook, const TotalCardLook(color: 0xFFCDB88A));

    await tester.tap(find.text('Total balance'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Match the app'));
    await tester.ensureVisible(find.text('Save total card'));
    await tester.tap(find.text('Save total card'));
    await tester.pumpAndSettle();
    expect(world.totalLook, const TotalCardLook());
  });

  testWidgets('a bank is added by searching for it, starting on a colour near its own', (tester) async {
    final world = await pumpApp(tester);
    await openAccounts(tester);
    await tester.ensureVisible(find.text('Add an account'));
    await tester.tap(find.text('Add an account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bank account'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Add account'));
    await tester.tap(find.text('Add account'));
    await tester.pumpAndSettle();
    expect(find.text('Choose one, or type its name'), findsOneWidget);
    expect(world.accounts, hasLength(1));

    await tester.enterText(find.widgetWithText(TextField, 'Which bank?'), 'isl');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bank Islam'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'How much is in it now'), '200000');
    await tester.ensureVisible(find.text('Add account'));
    await tester.tap(find.text('Add account'));
    await tester.pumpAndSettle();

    final added = world.accounts.last;
    expect((added.kind, added.name, added.balance, added.look.color, added.look.ink), (AccountKind.bank, 'Bank Islam', 200000, 0xFF151515, 0xFFE6C674));
  });

  testWidgets('a provider not on the list can be typed in', (tester) async {
    final world = await pumpApp(tester);
    await openAccounts(tester);
    await tester.ensureVisible(find.text('Add an account'));
    await tester.tap(find.text('Add an account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('E-wallet'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Which e-wallet?'), 'Office card');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Use “Office card”'));
    await tester.ensureVisible(find.text('Add account'));
    await tester.tap(find.text('Add account'));
    await tester.pumpAndSettle();
    expect((world.accounts.last.name, world.accounts.last.balance), ('Office card', 0));
  });
}
