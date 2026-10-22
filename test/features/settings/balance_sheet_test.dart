import 'package:bajet/features/accounts/domain/account_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/app_harness.dart';

void main() {
  Future<void> openBalance(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Balance'));
  }

  testWidgets('Settings → Balance offers to match the bank', (tester) async {
    await pumpApp(tester);
    await openBalance(tester);
    await tester.pumpAndSettle();
    expect(find.text('Your balance'), findsOneWidget);
    expect(find.text('bajet has RM1,500.00 from your entries.'), findsOneWidget);

    await tester.tap(find.text('Match what you really have'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextFormField, 'Bank app says'), findsOneWidget);
  });

  testWidgets('the starting balance can be fixed, moving every figure since', (tester) async {
    final world = await pumpApp(tester);
    await openBalance(tester);
    await settleUnderBar(tester);
    await tester.tap(find.text('Fix the starting balance instead'));
    await settleUnderBar(tester);
    expect(find.text('1,500.00'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextFormField, 'Balance on 01/07/2026'), '160000');
    await tester.tap(find.text('Save starting balance'));
    await settleUnderBar(tester);

    expect(world.accounts.single.openingBalance, 160000);
    expect(world.entries, isEmpty);
    expect(find.text('RM1,600.00'), findsWidgets);
    expect(find.text("Saved Main account's starting balance: RM1,600.00"), findsOneWidget);
    await tester.tap(find.text('Undo'));
    await settleUnderBar(tester);
    expect(world.accounts.single.openingBalance, 150000);
  });

  testWidgets("with several accounts, the starting balance fixed is the chosen account's", (tester) async {
    late int cash;
    final world = await pumpApp(tester, seed: (w) async {
      cash = await w.addAccount(const AccountDraft(kind: AccountKind.cash, name: 'Cash', balance: 8450, look: CardLook(color: 0xFF6B3F24, finish: CardFinish.leather)));
    });
    await openBalance(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fix the starting balance instead'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ValueKey('Which account?-$cash')));
    await tester.pumpAndSettle();
    expect(find.text('84.50'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), '9000');
    await tester.ensureVisible(find.text('Save starting balance'));
    await tester.tap(find.text('Save starting balance'));
    await tester.pumpAndSettle();
    expect({for (final a in world.accounts) a.name: a.openingBalance}, {'Main account': 150000, 'Cash': 9000});
  });
}
