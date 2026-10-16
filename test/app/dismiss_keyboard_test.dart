import 'package:bajet/features/accounts/domain/account_models.dart';
import 'package:bajet/features/accounts/presentation/card_designer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/app_harness.dart';

void main() {
  Future<void> openNickname(WidgetTester tester) async {
    await pumpApp(tester);
    showNewAccount(tester.element(find.byType(Scaffold).first), AccountKind.bank);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextField, 'Nickname (optional)'));
    await tester.pumpAndSettle();
  }

  bool typing(WidgetTester tester) => FocusManager.instance.primaryFocus?.context?.findAncestorWidgetOfExactType<EditableText>() != null;

  testWidgets('tapping outside a field puts the keyboard away, in any sheet or screen', (tester) async {
    await openNickname(tester);
    expect(typing(tester), isTrue);

    await tester.tap(find.text('Finish'));
    await tester.pumpAndSettle();
    expect(typing(tester), isFalse);
  });

  testWidgets('a drag that starts outside the field leaves the keyboard up', (tester) async {
    await openNickname(tester);
    await tester.drag(find.text('Finish'), const Offset(0, -60));
    await tester.pumpAndSettle();
    expect(typing(tester), isTrue);
  });

  testWidgets('tapping straight into another field moves the typing there', (tester) async {
    await openNickname(tester);
    await tester.tap(find.widgetWithText(TextField, 'How much is in it now'));
    await tester.pumpAndSettle();
    expect(typing(tester), isTrue);
    expect(FocusManager.instance.primaryFocus?.context?.findAncestorWidgetOfExactType<TextField>()?.decoration?.labelText, 'How much is in it now');
  });
}
