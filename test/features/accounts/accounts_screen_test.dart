import 'package:bajet/features/accounts/domain/account_models.dart';
import 'package:bajet/features/accounts/presentation/account_list.dart';
import 'package:bajet/features/accounts/presentation/account_stack.dart';
import 'package:bajet/features/accounts/presentation/card_face.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/fake_repositories.dart';

void addAccounts(FakeWorld w, int count) {
  for (var i = 0; i < count; i++) {
    w.addAccount(AccountDraft(kind: AccountKind.ewallet, name: 'Wallet $i', balance: 1000 * (i + 1), look: const CardLook(color: 0xFF00877F)));
  }
}

void main() {
  testWidgets("Today's stack stays the same height however many accounts there are", (tester) async {
    await pumpApp(tester, seed: (w) => addAccounts(w, 1));
    final two = tester.getSize(find.byType(AccountStack)).height;

    await pumpApp(tester, seed: (w) => addAccounts(w, 6));
    expect(tester.getSize(find.byType(AccountStack)).height, two);
    expect(find.text('7 accounts · tap to see them'), findsOneWidget);
  });

  testWidgets('the stack opens Your accounts, fanned out with no bottom bar, and back folds it away', (tester) async {
    await pumpApp(tester, seed: (w) => addAccounts(w, 3));
    await tester.tap(find.byType(AccountStack));
    await tester.pumpAndSettle();

    expect(find.text('Your accounts'), findsOneWidget);
    expect(find.byKey(const ValueKey('tab-Today')), findsNothing);
    // Fanned out, every account's name shows in its strip.
    for (final name in ['Main account', 'Wallet 0', 'Wallet 1', 'Wallet 2']) {
      expect(find.text(name).hitTestable(), findsWidgets, reason: name);
    }

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Your accounts'), findsNothing);
    expect(find.byKey(const ValueKey('tab-Today')), findsOneWidget);
  });

  testWidgets('a card opens upright among the others, and a swipe moves to the next', (tester) async {
    await pumpApp(tester, seed: (w) => addAccounts(w, 2));
    await tester.tap(find.byType(AccountStack));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Wallet 0').first);
    await tester.pumpAndSettle();

    expect(find.byType(PageView), findsOneWidget);
    expect(find.text('RM10.00 · E-wallet'), findsOneWidget);

    await tester.fling(find.byType(PageView), const Offset(-300, 0), 1000);
    await tester.pumpAndSettle();
    expect(find.text('RM20.00 · E-wallet'), findsOneWidget);

    await tester.tap(find.byType(BackButton).last);
    await tester.pumpAndSettle();
    expect(find.byType(PageView), findsNothing);
    expect(find.text('Your accounts'), findsOneWidget);
  });

  testWidgets("the two cards behind Today's total peek out by the same amount", (tester) async {
    await pumpApp(tester, seed: (w) => addAccounts(w, 2));
    final total = tester.getRect(find.byType(TotalCard)).top;
    double top(String name) => tester.getRect(find.ancestor(of: find.text(name).first, matching: find.byType(AccountCard))).top;
    expect(total - top('Main account'), AccountStack.peek);
    expect(top('Main account') - top('Wallet 0'), AccountStack.peek);
  });

  testWidgets('Your accounts leaves the total on Today, and scrolling opens the cards downward', (tester) async {
    await pumpApp(tester, seed: (w) => addAccounts(w, 3));
    await tester.tap(find.byType(AccountStack));
    await tester.pumpAndSettle();
    expect(find.byType(TotalCard), findsNothing);

    double top(String name) => tester.getRect(find.ancestor(of: find.text(name).first, matching: find.byType(AccountCard))).top;
    final first = top('Main account'), second = top('Wallet 0');
    expect(second - first, AccountListLayout.strip);

    // Scrolling part of the way: the top card holds, the next drops away.
    await tester.drag(find.byType(ListView), const Offset(0, -110));
    await tester.pumpAndSettle();
    expect(top('Main account'), first);
    expect(top('Wallet 0'), greaterThan(second));

    // Fully open, every card is whole with a gap beneath it.
    await tester.drag(find.byType(ListView), const Offset(0, -200));
    await tester.pumpAndSettle();
    final height = tester.getSize(find.byType(AccountCard).first).height;
    expect(top('Wallet 0') - top('Main account'), height + AccountListLayout.gap);
  });
}
