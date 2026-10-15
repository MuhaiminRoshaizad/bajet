import 'package:bajet/core/theme/app_theme.dart';
import 'package:bajet/features/accounts/domain/account_models.dart';
import 'package:bajet/features/accounts/presentation/card_face.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Account account({AccountKind kind = AccountKind.bank, String name = 'Bank', String? nickname, int balance = 124000, CardLook look = const CardLook(color: 0xFFC0262D)}) =>
    Account(id: 1, kind: kind, name: name, nickname: nickname, openingBalance: balance, balance: balance, look: look);

Future<void> show(WidgetTester tester, Widget card, {ThemeData? theme}) => tester.pumpWidget(MaterialApp(
      theme: theme ?? AppTheme.dark(),
      home: Scaffold(body: Padding(padding: const EdgeInsets.all(24), child: Center(child: SizedBox(width: 330, child: card)))),
    ));

void main() {
  testWidgets('a card shows its provider, balance and nickname, in a card shape', (tester) async {
    await show(tester, AccountCard(account: account(name: 'CIMB', nickname: 'Savings')));
    expect(find.text('CIMB'), findsNWidgets(2)); // at the top and as the wordmark
    expect(find.text('RM1,240.00'), findsOneWidget);
    expect(find.text('Savings'), findsOneWidget);
    final size = tester.getSize(find.byType(AccountCard));
    expect(size.width / size.height, closeTo(cardAspectRatio, 0.01));
  });

  testWidgets('without a nickname the card says what kind of account it is', (tester) async {
    await show(tester, AccountCard(account: account(kind: AccountKind.ewallet, name: 'Setel')));
    expect(find.text('E-wallet'), findsOneWidget);
  });

  test('text is dark on a light card, white on a dark one, or the colour picked', () {
    expect(cardInk(const CardLook(color: 0xFFF2C230)), const Color(0xFF14110A));
    expect(cardInk(const CardLook(color: 0xFF1C2F5E)), Colors.white);
    expect(cardInk(const CardLook(color: 0xFF151515, ink: 0xFFE6C674)), const Color(0xFFE6C674));
  });

  testWidgets('the back of a card carries no writing', (tester) async {
    await show(tester, AccountCard(account: account(name: 'CIMB'), back: true));
    expect(find.text('CIMB'), findsNothing);
    expect(find.text('RM1,240.00'), findsNothing);
  });

  test('a fuller wallet holds a thicker wad of bills, and an empty one none', () {
    expect([for (final sen in [0, -500, 500, 8450, 200000, 5000000]) billsFor(sen)], [0, 0, 2, 4, 5, 5]);
  });

  testWidgets('cash is a wallet with bills sticking out of the top', (tester) async {
    await show(tester, AccountCard(account: account(kind: AccountKind.cash, name: 'Cash', balance: 8450, look: const CardLook(color: 0xFF6B3F24, finish: CardFinish.leather))));
    expect(find.byKey(const ValueKey('bill-3')), findsOneWidget);
    final wallet = tester.getRect(find.byType(CashWallet));
    expect(tester.getRect(find.byKey(const ValueKey('bill-0'))).top, lessThan(wallet.top));
    expect(find.text('NOTES AND COINS'), findsOneWidget);
  });

  testWidgets('the total card counts the accounts and stops the dots at six', (tester) async {
    final many = [for (var i = 0; i < 8; i++) account()];
    await show(tester, TotalCard(look: const TotalCardLook(), balance: 401800, accounts: many, hint: 'tap to see them'), theme: AppTheme.light());
    expect(find.text('RM4,018.00'), findsOneWidget);
    expect(find.text('8 accounts · tap to see them'), findsOneWidget);
    expect(find.text('+2'), findsOneWidget);
  });
}
