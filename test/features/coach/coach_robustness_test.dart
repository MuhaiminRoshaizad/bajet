import 'package:bajet/features/coach/presentation/coach_controller.dart';
import 'package:bajet/features/coach/presentation/coach_chat_screen.dart';
import 'package:bajet/features/coach/domain/coach_client.dart';
import 'package:bajet/features/coach/domain/coach_proposals.dart';
import 'package:bajet/features/ledger/domain/ledger_models.dart';
import 'package:bajet/features/plan/domain/plan_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/fake_repositories.dart' show chatWith;
import 'coach_screen_test.dart' show ask, chatPage, openCoach;

/// The controller of the chat on screen.
CoachController coachOf(WidgetTester tester) => ProviderScope.containerOf(tester.element(chatPage))
    .read(coachControllerProvider(tester.widget<CoachChatScreen>(chatPage).chat).notifier);

void main() {
  testWidgets('a question sent twice in a rush reaches the coach once', (tester) async {
    final world = await openCoach(tester);
    final coach = coachOf(tester);
    coach.ask('How did this week go?');
    coach.ask('How did this week go?');
    await tester.pumpAndSettle();
    expect(world.coach.requests, hasLength(1));
    expect(find.text('How did this week go?'), findsOneWidget);
  });

  testWidgets('a card tapped twice in a rush logs once', (tester) async {
    final world = await openCoach(tester);
    world.coach.lookups.add(('bajet_propose_log', {'kind': 'spending', 'amount_rm': 12, 'category': 'Food', 'label': 'Lunch'}));
    await ask(tester, 'Log RM12 lunch');
    final coach = coachOf(tester);
    final at = coach.state.messages.length - 1;
    coach.confirm(at, 0);
    coach.confirm(at, 0);
    await tester.pumpAndSettle();
    expect(world.entries.where((e) => e.label == 'Lunch'), hasLength(1));
  });

  testWidgets('a card says a spend is a need, logs it as one, and leaves the allowance alone', (tester) async {
    final world = await openCoach(tester);
    world.coach.lookups.add(('bajet_propose_log', {'kind': 'spending', 'amount_rm': 18, 'category': 'Personal', 'label': 'Shampoo', 'spend_kind': 'need'}));
    await ask(tester, 'Log RM18 shampoo, I ran out');
    expect(find.text('Need'), findsOneWidget);
    expect(find.textContaining('Stays out of your'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Log it'));
    await tester.pumpAndSettle();
    expect(world.entries.singleWhere((e) => e.label == 'Shampoo').spendKind, SpendKind.need);
  });

  testWidgets('Change details opens the log sheet with the card in it, and the card follows what is saved', (tester) async {
    final world = await openCoach(tester);
    world.coach.lookups.add(('bajet_propose_log', {'kind': 'spending', 'amount_rm': 18, 'category': 'Personal', 'label': 'Shampoo', 'spend_kind': 'need'}));
    await ask(tester, 'Log RM18 shampoo');
    await tester.tap(find.text('Change details'));
    await tester.pumpAndSettle();
    expect(find.text('Log RM18.00'), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('amount')), '2050');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log RM20.50'));
    await settleUnderBar(tester);
    final saved = world.entries.singleWhere((e) => e.label == 'Shampoo');
    expect((saved.amount, saved.spendKind), (2050, SpendKind.need));
    expect(find.text('✓ Logged'), findsOneWidget);
    expect(find.text('RM20.50'), findsWidgets);
    expect(find.text('Change details'), findsNothing);
    // The bar's Undo and the card agree.
    await tester.tap(find.descendant(of: find.byType(SnackBar), matching: find.text('Undo')));
    await settleUnderBar(tester);
    expect(world.entries.where((e) => e.label == 'Shampoo'), isEmpty);
    expect(find.text('Undone, nothing changed'), findsOneWidget);
  });

  testWidgets('a card already settled elsewhere says so instead of opening the log sheet', (tester) async {
    late int rent;
    final world = await openCoach(tester, seed: (w) async {
      rent = await w.addRecurring(name: 'Rent', isIncome: false, amount: 50000, categoryKey: 'bills', nextDue: DateTime.utc(testToday.year, testToday.month, testToday.day + 3));
    });
    world.coach.lookups.add(('bajet_propose_log', {'kind': 'spending', 'for': 'Rent'}));
    await ask(tester, 'I paid the rent');
    await world.confirmRecurring(rent, due: world.recurring.single.nextDue, paidOn: testToday);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Change details'));
    await tester.pumpAndSettle();
    expect(find.text('Already changed elsewhere, nothing done'), findsOneWidget);
    expect(find.byType(TextField).hitTestable(), findsOneWidget, reason: 'only the chat box');
  });

  testWidgets('a card pays a bill at the real amount and moves it on, and Undo takes both back', (tester) async {
    final due = DateTime.utc(testToday.year, testToday.month, testToday.day + 3);
    final world = await openCoach(tester, seed: (w) async {
      await w.addRecurring(name: 'Rent', isIncome: false, amount: 50000, categoryKey: 'bills', nextDue: due);
    });
    world.coach.lookups.add(('bajet_propose_log', {'kind': 'spending', 'for': 'Rent', 'amount_rm': 492.4}));
    await ask(tester, 'I paid the rent, RM492.40');
    await tester.tap(find.widgetWithText(FilledButton, 'Pay it'));
    await tester.pumpAndSettle();
    expect(world.entries.singleWhere((e) => e.label == 'Rent').amount, 49240);
    expect(world.recurring.single.nextDue, DateTime.utc(due.year, due.month + 1, due.day));
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(world.entries.where((e) => e.label == 'Rent'), isEmpty);
    expect(world.recurring.single.nextDue, due);
  });

  testWidgets('spending on a planned event comes off its budget and out of the allowance', (tester) async {
    final world = await openCoach(tester, seed: (w) async {
      await w.addEvent(name: 'Dinner', isIncome: false, amount: 30000, categoryKey: 'gifts', date: DateTime.utc(testToday.year, testToday.month, testToday.day + 9));
    });
    world.coach.lookups.add(('bajet_propose_log', {'kind': 'spending', 'for': 'Dinner', 'amount_rm': 180}));
    await ask(tester, 'Spent RM180 on the dinner');
    expect(find.text('RM120.00 of RM300.00'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Log it'));
    await tester.pumpAndSettle();
    final spent = world.entries.singleWhere((e) => e.amount == 18000);
    expect(spent.event?.eventId, world.events.single.id);
    expect(spent.isWant(const {}), isFalse);
  });

  testWidgets('a bill already paid from the Plan tab is not paid again from an old card', (tester) async {
    late int rent;
    final world = await openCoach(tester, seed: (w) async {
      rent = await w.addRecurring(name: 'Rent', isIncome: false, amount: 50000, categoryKey: 'bills', nextDue: DateTime.utc(testToday.year, testToday.month, testToday.day + 3));
    });
    world.coach.lookups.add(('bajet_propose_log', {'kind': 'spending', 'for': 'Rent'}));
    await ask(tester, 'I paid the rent');
    expect(find.text('Pay this bill?'), findsOneWidget);

    await world.confirmRecurring(rent, due: world.recurring.single.nextDue, paidOn: testToday);
    await tester.pumpAndSettle();
    final due = world.recurring.single.nextDue;
    await tester.tap(find.widgetWithText(FilledButton, 'Pay it'));
    await tester.pumpAndSettle();
    expect(world.entries.where((e) => e.label == 'Rent'), hasLength(1), reason: 'paid once, from the Plan tab');
    expect(world.recurring.single.nextDue, due);
    expect(find.text('Already changed elsewhere, nothing done'), findsOneWidget);
  });

  testWidgets('a bill card saved in an old chat still pays at its plan, once', (tester) async {
    final due = DateTime.utc(testToday.year, testToday.month, testToday.day + 3);
    final world = await openCoach(tester, seed: (w) async {
      final id = await w.addRecurring(name: 'Rent', isIncome: false, amount: 50000, categoryKey: 'bills', nextDue: due);
      w.coachChat.restore([
        chatWith([
          CoachMessage(fromUser: true, text: 'I paid the rent', sentAt: DateTime(2026), id: 1),
          CoachMessage(
            fromUser: false,
            text: 'Put up for you.',
            sentAt: DateTime(2026),
            id: 2,
            cards: [CoachCard(BillPaidProposal(RecurringItem(id: id, name: 'Rent', amount: 50000, categoryKey: 'bills', isIncome: false, nextDue: due)))],
          ),
        ], id: 50),
      ]);
    });
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('chat-50')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Mark paid'));
    await tester.pumpAndSettle();
    expect(world.entries.singleWhere((e) => e.label == 'Rent').amount, 50000);
    expect(find.text('✓ Marked paid'), findsOneWidget);
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(world.entries.where((e) => e.label == 'Rent'), isEmpty);
    expect(world.recurring.single.nextDue, due);
  });

  testWidgets('after three messages turned away in a row, more spam is turned away without asking anyone', (tester) async {
    final world = await openCoach(tester);
    world.coach.gateKind = 'off_topic';
    for (final m in ['Write a poem', 'Tell me a joke', 'What is the capital of France']) {
      await ask(tester, m);
    }
    expect(world.coach.gateRequests, hasLength(3));
    await ask(tester, 'Sing me a song');
    await ask(tester, 'Pretty please');
    expect(world.coach.gateRequests, hasLength(3), reason: 'spam past the third costs nothing');

    expect(find.textContaining('two-minute teh break'), findsNWidgets(2));

    // Once the two minutes are up, a money question is heard as usual.
    world.coach.gateKind = 'money';
    world.clock = world.clock.add(const Duration(minutes: 2));
    await ask(tester, 'How did this week go?');
    expect(find.text('You are on track.'), findsOneWidget);
  });
}
