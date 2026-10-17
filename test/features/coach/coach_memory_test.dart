import 'package:bajet/core/database/app_database.dart' as db;
import 'package:bajet/features/coach/data/drift_coach_chat_repository.dart';
import 'package:bajet/features/coach/domain/coach_client.dart';
import 'package:bajet/features/coach/presentation/coach_key_screen.dart';
import 'package:bajet/features/coach/domain/coach_memory.dart';
import 'package:bajet/features/coach/domain/coach_proposals.dart';
import 'package:bajet/features/coach/domain/coach_settings.dart';
import 'package:bajet/features/ledger/domain/ledger_models.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/app_harness.dart';
import 'coach_screen_test.dart' show ask, openCoach;

CoachMessage said(bool user, String text, DateTime at) => CoachMessage(fromUser: user, text: text, sentAt: at, face: user ? null : CoachFace.aina);

void main() {
  test('the model gets the last twenty messages, starting at a question', () {
    final at = DateTime(2026, 10, 17);
    final chat = [for (var i = 0; i < 25; i++) said(i.isEven, 'm$i', at)];
    final sent = forModel(chat);
    expect(sent.first.fromUser, isTrue);
    expect(sent.length, lessThanOrEqualTo(coachMemoryWindow));
    expect(sent.last.text, 'm24');
  });

  test('older chats are searched by every word, newest first, with their day', () {
    final older = [
      said(true, 'How much on food this week?', DateTime(2026, 10, 10)),
      said(false, 'RM58.40 on food, mostly dinners.', DateTime(2026, 10, 10)),
      said(true, 'And transport?', DateTime(2026, 10, 11)),
    ];
    final r = searchPastChats({'query': 'food dinners'}, older);
    expect(r.text, '- 10/10/2026 Coach: RM58.40 on food, mostly dinners.');
    expect(searchPastChats({'query': 'crypto'}, older).text, 'No earlier chat mentions that.');
    expect(searchPastChats(const {}, older).failed, isTrue);
  });

  test('a remembered chat comes back with its faces, lookups and cards, and Forget can be undone', () async {
    final database = db.AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repo = DriftCoachChatRepository(database);
    final card = CoachCard(
      LogProposal(EntryDraft(day: DateTime.utc(2026, 10, 18), isIncome: false, amount: 1200, categoryKey: 'food', label: 'Lunch', accountId: 1), 'Food', 'Cash'),
      state: CardState.done,
      undoId: 7,
    );
    await repo.add(said(true, 'Log RM12 lunch', DateTime(2026, 10, 18, 12)));
    final id = await repo.add(CoachMessage(fromUser: false, text: 'Put up for you.', sentAt: DateTime(2026, 10, 18, 12), face: CoachFace.bajety, looked: const ['Accounts']));
    final loaded = await repo.load();
    await repo.saveCards(id, loaded.last.withCards([card]));

    final back = await repo.load();
    expect([for (final m in back) (m.fromUser, m.text, m.face)], [(true, 'Log RM12 lunch', null), (false, 'Put up for you.', CoachFace.bajety)]);
    expect(back.last.looked, ['Accounts']);
    final c = back.last.cards.single;
    expect((c.state, c.undoId, c.proposal.amount, (c.proposal as LogProposal).accountName), (CardState.done, 7, 1200, 'Cash'));

    final gone = await repo.clear();
    expect(await repo.load(), isEmpty);
    await repo.restore(gone);
    expect([for (final m in await repo.load()) m.text], ['Log RM12 lunch', 'Put up for you.']);
  });

  testWidgets('yesterday\'s chat is there after a restart, under its day, and the coach can search older ones', (tester) async {
    final yesterday = DateTime(testToday.year, testToday.month, testToday.day - 1, 20);
    final world = await openCoach(tester, seed: (w) {
      for (var i = 0; i < 22; i++) {
        w.coachChat.saved.add(said(i.isEven, 'old $i', yesterday).withId(i + 1));
      }
    });
    // The chat opens at its latest message; the top holds the day it began.
    await tester.fling(find.byType(ListView).first, const Offset(0, 4000), 4000);
    await tester.pumpAndSettle();
    expect(find.text('Yesterday'), findsOneWidget);
    expect(find.text('Remembered on this phone only'), findsOneWidget);

    await ask(tester, 'What did we talk about?');
    expect(world.coach.requests.last.tools.map((t) => t['name']), contains('bajet_past_chats'));
    expect(world.coach.requests.last.messages.length, lessThanOrEqualTo(coachMemoryWindow));
    expect(world.coachChat.saved.last.text, 'You are on track.');
    // Today's question opens under its own day; the Today tab is not it.
    expect(find.descendant(of: find.byType(ListView).first, matching: find.text('Today')), findsOneWidget);
  });

  testWidgets('Forget everything empties the chat after asking, and Undo brings it back', (tester) async {
    final world = await openCoach(tester);
    await ask(tester, 'How did this week go?');
    expect(world.coachChat.saved, hasLength(2));

    await tester.tap(find.byKey(const ValueKey('tab-Today')));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Key saved'), 200);
    await tester.drag(find.byType(ListView).last, const Offset(0, -200));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Key saved'));
    await tester.pumpAndSettle();
    final page = find.descendant(of: find.byType(CoachKeyScreen), matching: find.byType(Scrollable)).first;
    await tester.scrollUntilVisible(find.textContaining('Forget everything'), 300, scrollable: page);
    expect(find.text('Forget everything (2 messages)'), findsOneWidget);
    await tester.drag(page, const Offset(0, -300));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Forget everything (2 messages)'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Forget'));
    await tester.pumpAndSettle();
    expect(world.coachChat.saved, isEmpty);
    expect(find.text('Nothing to forget'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(world.coachChat.saved, hasLength(2));
  });

  testWidgets('with memory off nothing is kept', (tester) async {
    final world = await openCoach(tester, seed: (w) => w.coachSettings.saveSettings(const CoachSettings(remember: false)));
    await ask(tester, 'How did this week go?');
    expect(find.text('You are on track.'), findsOneWidget);
    expect(world.coachChat.saved, isEmpty);
    expect(find.text('Remembered on this phone only'), findsNothing);
  });
}
