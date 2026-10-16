import 'package:bajet/features/accounts/presentation/account_activity.dart';
import 'package:bajet/features/ledger/domain/ledger_models.dart';
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
    expect(find.byKey(const ValueKey('tab-Today')).hitTestable(), findsNothing);
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
    await tester.tap(find.text('Wallet 0').hitTestable().first);
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
    expect(find.byType(TotalCard).hitTestable(), findsNothing);

    double top(String name) => tester.getRect(find.ancestor(of: find.text(name).hitTestable().first, matching: find.byType(AccountCard))).top;
    final first = top('Main account'), second = top('Wallet 0');
    expect(second - first, AccountListLayout.strip);

    // Scrolling part of the way: the top card holds, the next drops away.
    await tester.drag(find.byType(ListView).last, const Offset(0, -110));
    await tester.pumpAndSettle();
    expect(top('Main account'), first);
    expect(top('Wallet 0'), greaterThan(second));

    // Fully open, every card is whole with a gap beneath it.
    await tester.drag(find.byType(ListView).last, const Offset(0, -200));
    await tester.pumpAndSettle();
    final height = tester.getSize(find.byType(AccountCard).first).height;
    expect(top('Wallet 0') - top('Main account'), height + AccountListLayout.gap);
  });

  testWidgets("Today's stack lends its cards to Your accounts and has them back once they land", (tester) async {
    await pumpApp(tester, seed: (w) => addAccounts(w, 2));
    double stackOpacity() => tester.widget<Opacity>(find.ancestor(of: find.byType(AccountStack), matching: find.byType(Opacity)).first).opacity;
    expect(stackOpacity(), 1);

    await tester.tap(find.byType(AccountStack));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    // Mid-flight: one of each card, flying, and Today's own copies hidden.
    expect(stackOpacity(), 0);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(BackButton).last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(stackOpacity(), 0);
    await tester.pumpAndSettle();
    expect(stackOpacity(), 1);
  });

  testWidgets("while a card flies to its own page and back, the list's copies stay hidden", (tester) async {
    await pumpApp(tester, seed: (w) => addAccounts(w, 2));
    await tester.tap(find.byType(AccountStack));
    await tester.pumpAndSettle();
    List<double> listOpacities() => [
          for (final o in tester.widgetList<Opacity>(find.descendant(of: find.byType(AccountList), matching: find.byType(Opacity)))) o.opacity,
        ];
    expect(listOpacities(), everyElement(1.0));

    await tester.tap(find.text('Wallet 0').hitTestable().first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    expect(listOpacities(), everyElement(0.0));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(BackButton).last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    expect(listOpacities(), everyElement(0.0));
    await tester.pumpAndSettle();
    expect(listOpacities(), everyElement(1.0));
  });

  testWidgets("scrolling down a card's page shows that account's own activity, moves included", (tester) async {
    await pumpApp(tester, seed: (w) {
      addAccounts(w, 1);
      w.add(EntryDraft(day: testToday, isIncome: false, amount: 450, categoryKey: 'food', label: 'Coffee', accountId: 2));
      w.add(EntryDraft(day: testToday, isIncome: false, amount: 900, categoryKey: 'food', label: 'Lunch', accountId: 1));
      w.transfer(fromId: 1, toId: 2, amount: 5000, day: testToday);
    });
    await tester.tap(find.byType(AccountStack));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Wallet 0').hitTestable().first);
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Wallet 0 activity'), 200, scrollable: find.byType(Scrollable).last);
    await tester.pumpAndSettle();
    Finder inActivity(String text) => find.descendant(of: find.byType(AccountActivity), matching: find.text(text));
    expect(inActivity('Coffee'), findsOneWidget);
    expect(inActivity('Moved from Main account'), findsOneWidget);
    expect(inActivity('+RM50.00'), findsOneWidget);
    // Spent from the other account, so not this one's.
    expect(inActivity('Lunch'), findsNothing);
  });

  testWidgets('holding a card picks it up, dragging it reorders the cards, and Today follows', (tester) async {
    final world = await pumpApp(tester, seed: (w) => addAccounts(w, 2));
    await tester.tap(find.byType(AccountStack));
    await tester.pumpAndSettle();

    final press = await tester.startGesture(tester.getCenter(find.text('Wallet 1').hitTestable().first));
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pump(const Duration(milliseconds: 500));
    // Picked up: the slot it will land in is outlined.
    expect(find.byType(CustomPaint).hitTestable(), findsWidgets);
    for (var i = 0; i < 10; i++) {
      await press.moveBy(const Offset(0, -16));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await press.up();
    await tester.pumpAndSettle();
    expect([for (final a in world.accounts) a.name], ['Wallet 1', 'Main account', 'Wallet 0']);

    await tester.tap(find.byType(BackButton).last);
    await tester.pumpAndSettle();
    expect([for (final a in tester.widget<AccountStack>(find.byType(AccountStack)).accounts) a.name], ['Wallet 1', 'Main account', 'Wallet 0']);
  });

  testWidgets('a quick tap still opens a card, and a scroll never picks one up', (tester) async {
    final world = await pumpApp(tester, seed: (w) => addAccounts(w, 2));
    await tester.tap(find.byType(AccountStack));
    await tester.pumpAndSettle();

    await tester.drag(find.text('Wallet 0').hitTestable().first, const Offset(0, -120));
    await tester.pumpAndSettle();
    expect([for (final a in world.accounts) a.name], ['Main account', 'Wallet 0', 'Wallet 1']);

    await tester.tap(find.text('Wallet 1').hitTestable().first);
    await tester.pumpAndSettle();
    expect(find.text('Move money from Wallet 1'), findsOneWidget);
  });
}
