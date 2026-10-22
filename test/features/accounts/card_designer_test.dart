import 'package:bajet/features/accounts/domain/account_models.dart';
import 'package:bajet/features/accounts/presentation/provider_picker.dart';
import 'package:bajet/features/accounts/presentation/account_stack.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/app_harness.dart';

Future<void> openAccounts(WidgetTester tester) async {
  await tester.tap(find.byType(AccountStack));
  await tester.pumpAndSettle();
}

final providerSheet = find.byKey(const ValueKey('provider-search'));

/// Opens the bank or e-wallet list from the field labelled [label], searches
/// it for [query], then taps [row].
Future<void> searchProvider(WidgetTester tester, String label, String query, String row) async {
  await tester.tap(find.widgetWithText(TextField, label));
  await tester.pumpAndSettle();
  await tester.enterText(providerSheet, query);
  await tester.pumpAndSettle();
  await tester.tap(find.text(row));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets("the pencil on an account changes its card's colour, finish and nickname, not its balance", (tester) async {
    final world = await pumpApp(tester);
    await openAccounts(tester);
    await tester.tap(find.text('Main account').hitTestable().first);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Edit this card'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.bySemanticsLabel('Black and gold'));

    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Black and gold'));
    await tester.ensureVisible(find.text('Gloss'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gloss'));
    await tester.enterText(find.widgetWithText(TextField, 'Nickname (optional)'), 'Savings');
    await tester.ensureVisible(find.text('Save card'));
    await tester.tap(find.text('Save card'));
    await tester.pumpAndSettle();

    final main = world.accounts.single;
    expect((main.look, main.nickname, main.balance), (const CardLook(color: 0xFF151515, ink: 0xFFE6C674, finish: CardFinish.gloss), 'Savings', 150000));
  });

  testWidgets("cash is offered leather or suede and none of a card's finishes, and keeps the one picked", (tester) async {
    final world = await pumpApp(tester, seed: (w) => w.addAccount(const AccountDraft(kind: AccountKind.cash, name: 'Cash', look: CardLook(color: 0xFF6B3F24, finish: CardFinish.leather))));
    await openAccounts(tester);
    await tester.tap(find.text('Cash').hitTestable().first);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Edit this card'));
    await tester.pumpAndSettle();
    expect(find.text('Leather'), findsOneWidget);
    expect(find.text('Mirror'), findsNothing);

    await tester.ensureVisible(find.text('Suede'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Suede'));
    await tester.ensureVisible(find.text('Save card'));
    await tester.tap(find.text('Save card'));
    await tester.pumpAndSettle();
    expect(world.accounts.last.look.finish, CardFinish.suede);
  });

  testWidgets("a card is offered six finishes and brushed metal isn't one", (tester) async {
    await pumpApp(tester);
    await openAccounts(tester);
    await tester.tap(find.text('Main account').hitTestable().first);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Edit this card'));
    await tester.pumpAndSettle();
    for (final f in ['Matte', 'Gloss', 'Mirror', 'Pearl', 'Frosted glass', 'Guilloché']) {
      expect(find.widgetWithText(ChoiceChip, f), findsOneWidget);
    }
    expect(find.text('Brushed metal'), findsNothing);
  });

  testWidgets('the total card is restyled from Settings, and Match the app puts it back', (tester) async {
    final world = await pumpApp(tester);
    Future<void> openTotal() async {
      await tester.tap(find.text('Total card'));
      await tester.pumpAndSettle();
    }

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Accounts'));
    await tester.pumpAndSettle();
    await openTotal();
    await tester.ensureVisible(find.bySemanticsLabel('Champagne'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Champagne'));
    await tester.ensureVisible(find.text('Save total card'));
    await tester.tap(find.text('Save total card'));
    await tester.pumpAndSettle();
    expect(world.totalLook, const TotalCardLook(color: 0xFFCDB88A));
    expect(find.text('Saved the total card'), findsOneWidget);

    await openTotal();
    await tester.ensureVisible(find.bySemanticsLabel('Match the app'));
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
    expect(find.text('Choose one, or search for its name'), findsOneWidget);
    expect(world.accounts, hasLength(1));

    await searchProvider(tester, 'Which bank?', 'isl', 'Bank Islam');
    await tester.enterText(find.widgetWithText(TextFormField, 'How much is in it now'), '200000');
    await tester.ensureVisible(find.text('Add account'));
    await tester.tap(find.text('Add account'));
    await tester.pumpAndSettle();

    final added = world.accounts.last;
    expect((added.kind, added.name, added.balance, added.look.color, added.look.ink), (AccountKind.bank, 'Bank Islam', 200000, 0xFF151515, 0xFFE6C674));
    expect(find.text('Added Bank Islam'), findsWidgets);
    // Each page under the bar draws it; the top one is the one seen.
    await tester.tap(find.text('Undo').hitTestable().last);
    await tester.pumpAndSettle();
    expect(world.accounts, hasLength(1));
  });

  testWidgets('a provider not on the list can be typed in', (tester) async {
    final world = await pumpApp(tester);
    await openAccounts(tester);
    await tester.ensureVisible(find.text('Add an account'));
    await tester.tap(find.text('Add an account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('E-wallet'));
    await tester.pumpAndSettle();
    await searchProvider(tester, 'Which e-wallet?', 'Office card', 'Not listed? Use “Office card”');
    await tester.ensureVisible(find.text('Add account'));
    await tester.tap(find.text('Add account'));
    await tester.pumpAndSettle();
    expect((world.accounts.last.name, world.accounts.last.balance), ('Office card', 0));
  });

  testWidgets('the bank dropdown sits in the same well as every other field', (tester) async {
    await pumpApp(tester);
    await openAccounts(tester);
    await tester.ensureVisible(find.text('Add an account'));
    await tester.tap(find.text('Add an account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bank account'));
    await tester.pumpAndSettle();
    InputDecoration decoration(Finder field) => tester.widget<InputDecorator>(find.descendant(of: field, matching: find.byType(InputDecorator)).first).decoration;
    final bank = decoration(find.byType(ProviderPicker));
    final nickname = decoration(find.widgetWithText(TextField, 'Nickname (optional)'));
    expect((bank.filled, bank.fillColor, bank.enabledBorder, bank.focusedBorder), (nickname.filled, nickname.fillColor, nickname.enabledBorder, nickname.focusedBorder));
    expect(bank.filled, isTrue);
  });

  testWidgets('the bank list opens grouped with the keyboard down, filters as it is searched, and a pick colours the card', (tester) async {
    final world = await pumpApp(tester);
    await openAccounts(tester);
    await tester.ensureVisible(find.text('Add an account'));
    await tester.tap(find.text('Add an account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bank account'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextField, 'Which bank?'));
    await tester.pumpAndSettle();
    expect(find.text('MOST USED'), findsOneWidget);
    expect(find.text('DIGITAL BANKS'), findsOneWidget);
    expect(tester.testTextInput.isVisible, isFalse, reason: 'the list is there to scroll first');
    // Further down the list, reached by scrolling rather than typing.
    await tester.scrollUntilVisible(find.text('Agrobank'), 200, scrollable: find.descendant(of: find.byType(BottomSheet), matching: find.byType(Scrollable)).last);
    expect(find.text('Agrobank'), findsOneWidget);

    await tester.enterText(providerSheet, 'cim');
    await tester.pumpAndSettle();
    expect(find.text('MOST USED'), findsNothing);
    await tester.tap(find.text('CIMB').last);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Add account'));
    await tester.tap(find.text('Add account'));
    await tester.pumpAndSettle();
    expect((world.accounts.last.name, world.accounts.last.look.color), ('CIMB', 0xFFC0262D));
  });

  testWidgets('Match my card takes the colour from a photo and keeps only the colour', (tester) async {
    final world = await pumpApp(tester);
    await openAccounts(tester);
    await tester.tap(find.text('Main account').hitTestable().first);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Edit this card'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Match my card'));
    await tester.tap(find.text('Match my card'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose a photo'));
    await tester.pumpAndSettle();
    // The table fills most of the photo, but only the frame is counted, so
    // the card's colour comes first.
    expect(find.text('From inside the frame'), findsOneWidget);
    expect(find.bySemanticsLabel('Colour 2 from your photo'), findsOneWidget);
    await tester.tap(find.text('Use this colour'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Save card'));
    await tester.tap(find.text('Save card'));
    await tester.pumpAndSettle();
    expect(world.accounts.single.look, const CardLook(color: 0xFF7A1F2B));
  });

  testWidgets('tapping the photo takes the exact colour under the finger', (tester) async {
    final world = await pumpApp(tester);
    await openAccounts(tester);
    await tester.tap(find.text('Main account').hitTestable().first);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Edit this card'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Match my card'));
    await tester.tap(find.text('Match my card'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Take a photo'));
    await tester.pumpAndSettle();

    // The photo's top left corner is table.
    final photo = tester.getRect(find.byKey(const ValueKey('photo')));
    await tester.tapAt(photo.topLeft + const Offset(4, 4));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Use this colour'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save card'));
    await tester.tap(find.text('Save card'));
    await tester.pumpAndSettle();
    expect(world.accounts.single.look.color, 0xFFE8E8E8);
  });

  testWidgets('cancelling the photo leaves the colour as it was', (tester) async {
    final world = await pumpApp(tester);
    world.photos.next = null;
    await openAccounts(tester);
    await tester.tap(find.text('Main account').hitTestable().first);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Edit this card'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Match my card'));
    await tester.tap(find.text('Match my card'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose a photo'));
    await tester.pumpAndSettle();
    expect(find.text('Use this colour'), findsNothing);
    await tester.ensureVisible(find.text('Save card'));
    await tester.tap(find.text('Save card'));
    await tester.pumpAndSettle();
    expect(world.accounts.single.look.color, firstAccountColor);
  });

  testWidgets("an upgrade's Main account can be renamed to the bank it really is, keeping its colour", (tester) async {
    final world = await pumpApp(tester);
    await openAccounts(tester);
    await tester.tap(find.text('Main account').hitTestable().first);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Edit this card'));
    await tester.pumpAndSettle();

    await searchProvider(tester, 'Which bank?', 'cim', 'CIMB');
    await tester.ensureVisible(find.text('Save card'));
    await tester.tap(find.text('Save card'));
    await tester.pumpAndSettle();
    final main = world.accounts.single;
    expect((main.name, main.look.color, main.balance), ('CIMB', 0xFF4A5866, 150000));
    expect(find.text("Saved CIMB's card"), findsWidgets);
    await tester.tap(find.text('Undo').hitTestable().last);
    await tester.pumpAndSettle();
    expect(world.accounts.single.name, 'Main account');
  });
}
