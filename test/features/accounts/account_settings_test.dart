import 'package:bajet/features/accounts/domain/account_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/app_harness.dart';

Future<void> openAccountSettings(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Settings'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Accounts'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Settings lists every card, the total first, and each opens the designer', (tester) async {
    final world = await pumpApp(tester, seed: (w) => w.addAccount(const AccountDraft(kind: AccountKind.cash, name: 'Cash', nickname: 'Wallet', balance: 8450, look: CardLook(color: 0xFF6B3F24, finish: CardFinish.leather))));
    await openAccountSettings(tester);
    expect(find.byKey(const ValueKey('tab-Today')), findsNothing);

    final rows = [for (final t in ['Total card', 'Main account', 'Cash']) tester.getTopLeft(find.text(t)).dy];
    expect(rows, orderedEquals([...rows]..sort()));
    expect(find.text('Wallet · RM84.50'), findsOneWidget);

    await tester.tap(find.text('Cash'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Tan'));
    await tester.ensureVisible(find.text('Save card'));
    await tester.tap(find.text('Save card'));
    await tester.pumpAndSettle();
    expect(world.accounts.last.look.color, 0xFFA8693A);
  });
}
