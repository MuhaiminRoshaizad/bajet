import 'package:bajet/features/accounts/domain/account_models.dart';
import 'package:bajet/features/accounts/presentation/account_stack.dart';
import 'package:bajet/features/accounts/presentation/account_view_screen.dart';
import 'package:bajet/features/ledger/domain/ledger_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/fake_repositories.dart';
import 'account_settings_test.dart' show openAccountSettings;

const _cash = AccountDraft(kind: AccountKind.cash, name: 'Cash', balance: 8450, look: CardLook(color: 0xFF6B3F24, finish: CardFinish.leather));

/// Cash with a lunch logged to it.
void _usedCash(FakeWorld w) {
  w.addAccount(_cash);
  w.add(EntryDraft(day: demoSettings.openingDate, isIncome: false, amount: 1200, categoryKey: 'food', label: 'Lunch', accountId: 2));
}

Future<void> _editCash(WidgetTester tester) async {
  await tester.tap(find.byType(AccountStack));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Cash').hitTestable().first);
  await tester.pumpAndSettle();
  await tester.tap(find.byTooltip('Edit this card'));
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text('Delete account'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the only account cannot be deleted, and says why', (tester) async {
    await pumpApp(tester);
    await openAccountSettings(tester);
    await tester.tap(find.text('Main account'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Delete account'));
    expect(tester.widget<OutlinedButton>(find.ancestor(of: find.text('Delete account'), matching: find.byType(OutlinedButton))).onPressed, isNull);
    expect(find.textContaining("It's your only account"), findsOneWidget);
  });

  testWidgets('an account never used goes after a plain confirm, and Undo brings it back', (tester) async {
    final world = await pumpApp(tester, seed: (w) => w.addAccount(_cash));
    await openAccountSettings(tester);
    await tester.tap(find.text('Cash'));
    await settleUnderBar(tester);
    await tester.ensureVisible(find.text('Delete account'));
    await tester.tap(find.text('Delete account'));
    await settleUnderBar(tester);
    expect(find.text('Nothing has been logged to it. Your total drops by RM84.50.'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await settleUnderBar(tester);
    expect([for (final a in world.accounts) a.name], ['Main account']);
    expect(find.text('Cash'), findsNothing);
    expect(find.text('Deleted Cash'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await settleUnderBar(tester);
    expect([for (final a in world.accounts) a.name], ['Main account', 'Cash']);
  });

  testWidgets('a used account moves its history to the account picked, and the card page closes', (tester) async {
    final world = await pumpApp(tester, seed: _usedCash);
    final total = world.accounts.fold<int>(0, (sum, a) => sum + a.balance);
    await _editCash(tester);
    await tester.tap(find.text('Delete account'));
    await settleUnderBar(tester);
    expect(find.text('1 entry uses it.'), findsOneWidget);
    expect(find.text('RM72.50 goes with them. Your total stays the same.'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await settleUnderBar(tester);
    expect(find.byType(AccountViewScreen), findsNothing);
    expect(world.accounts.single.balance, total);
    expect(world.entries.single.accountId, world.accounts.single.id);
    // Today's page lies under Your accounts and shows the same snackbar unseen.
    expect(find.text('Deleted Cash. Its history moved to Main account.'), findsWidgets);
  });

  testWidgets('Delete them too takes its history with it', (tester) async {
    final world = await pumpApp(tester, seed: _usedCash);
    await _editCash(tester);
    await tester.tap(find.text('Delete account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete them too'));
    await tester.pumpAndSettle();
    expect(find.text('Move to'), findsNothing);

    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(world.entries, isEmpty);
    expect([for (final a in world.accounts) a.name], ['Main account']);
  });

  testWidgets('Keep leaves everything as it was', (tester) async {
    final world = await pumpApp(tester, seed: _usedCash);
    await _editCash(tester);
    await tester.tap(find.text('Delete account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Keep'));
    await tester.pumpAndSettle();
    expect(world.accounts, hasLength(2));
    expect(find.text('Delete account'), findsOneWidget);
  });
}
