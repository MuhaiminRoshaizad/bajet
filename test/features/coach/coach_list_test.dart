import 'package:bajet/core/theme/app_motion.dart';
import 'package:bajet/features/coach/domain/coach_client.dart';
import 'package:bajet/features/coach/domain/coach_settings.dart';
import 'package:bajet/features/coach/presentation/coach_attention.dart';
import 'package:bajet/features/coach/presentation/coach_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/fake_repositories.dart';
import 'coach_screen_test.dart' show ask, chatPage, chatRows, openCoach;

CoachMessage said(bool user, String text, DateTime at) => CoachMessage(fromUser: user, text: text, sentAt: at, face: user ? null : CoachFace.aina);

void main() {
  test('a chat is labelled by when it was last used, as chat lists do', () {
    final today = DateTime.utc(2026, 10, 20);
    expect(chatTimeLabel(DateTime(2026, 10, 20, 14, 5), today), '14:05');
    expect(chatTimeLabel(DateTime(2026, 10, 19, 9), today), 'Yesterday');
    expect(chatTimeLabel(DateTime(2026, 10, 17, 9), today), 'Sat');
    expect(chatTimeLabel(DateTime(2026, 10, 2, 9), today), '02/10');
    expect(chatTimeLabel(DateTime(2025, 12, 30, 9), today), '30/12/2025');
  });

  testWidgets('chats are listed pinned first, then newest, each with its coach and last line', (tester) async {
    final day = DateTime(testToday.year, testToday.month, testToday.day, 9);
    await openCoach(tester, open: false, seed: (w) => w.coachChat.restore([
          chatWith([said(true, 'Rent next month', day.subtract(const Duration(days: 3))), said(false, 'You keep RM1,390.50.', day.subtract(const Duration(days: 3)))], id: 1),
          chatWith([said(true, 'Laptop by January?', day.subtract(const Duration(days: 9)))], id: 2).copyWith(pinned: true),
          chatWith([said(true, 'Why was last week high?', day), said(false, 'Food was RM142.30.', day)], id: 3, face: CoachFace.aina),
        ]));
    final rows = [for (final e in chatRows.evaluate()) (e.widget.key! as ValueKey<String>).value];
    expect(rows, ['chat-2', 'chat-3', 'chat-1']);
    expect(find.text('You: Laptop by January?'), findsOneWidget);
    expect(find.text('Food was RM142.30.'), findsOneWidget);
    expect(find.byIcon(Icons.push_pin_rounded), findsOneWidget);
    expect(find.text('Remembered on this phone only'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('chat-3')));
    await tester.pumpAndSettle();
    expect(find.descendant(of: chatPage, matching: find.text('Food was RM142.30.')), findsOneWidget);
    expect(find.descendant(of: chatPage, matching: find.text('Aina')), findsOneWidget);
  });

  testWidgets('a new chat left without a question is not kept; one asked in is, named after it', (tester) async {
    final world = await openCoach(tester, open: false);
    expect(find.text('No chats yet'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('new-chat')));
    await tester.pumpAndSettle();
    expect(chatPage, findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(chatRows, findsNothing);
    expect(await world.coachChat.load(), isEmpty);

    await tester.tap(find.text('Start a chat'));
    await tester.pumpAndSettle();
    await ask(tester, 'How did this week go?');
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(chatRows, findsOneWidget);
    expect(find.text('How did this week go?'), findsOneWidget);
    expect((await world.coachChat.load()).single.title, 'How did this week go?');
  });

  testWidgets('the new chat button sits centred over the log button', (tester) async {
    await openCoach(tester, open: false);
    final newChat = tester.getCenter(find.byKey(const ValueKey('new-chat')));
    final log = tester.getRect(find.byKey(const ValueKey('add')));
    expect(newChat.dx, closeTo(log.center.dx, 1));
    expect(newChat.dy, lessThan(log.top));
  });

  Future<void> seedTwo(FakeWorld w) async {
    final day = DateTime(testToday.year, testToday.month, testToday.day, 9);
    await w.coachChat.restore([
      chatWith([said(true, 'Rent next month', day), said(false, 'You keep RM1,390.50.', day)], id: 1),
      chatWith([said(true, 'Laptop by January?', day.subtract(const Duration(days: 1))), said(false, 'Yes, with a little room.', day.subtract(const Duration(days: 1)))], id: 2),
    ]);
  }

  testWidgets('search finds chats by their name or anything said in them', (tester) async {
    await openCoach(tester, open: false, seed: seedTwo);
    await tester.enterText(find.byKey(const ValueKey('search-chats')), 'little room');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('chat-2')), findsOneWidget);
    expect(find.byKey(const ValueKey('chat-1')), findsNothing);

    await tester.enterText(find.byKey(const ValueKey('search-chats')), 'crypto');
    await tester.pumpAndSettle();
    expect(find.text('No chats mention “crypto”.'), findsOneWidget);
    await tester.tap(find.byTooltip('Clear the search'));
    // The chats coming back rise in, each a stagger after the last: drawn
    // first, then given the time to start and finish.
    await tester.pump();
    await tester.pump(AppMotion.enter + AppMotion.stagger * 4);
    await tester.pumpAndSettle();
    expect(chatRows, findsNWidgets(2));
  });

  testWidgets('holding a chat pins it to the top, and renames it once it has a name', (tester) async {
    final world = await openCoach(tester, open: false, seed: seedTwo);
    await tester.longPress(find.byKey(const ValueKey('chat-2')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pin chat'));
    await tester.pumpAndSettle();
    expect((chatRows.evaluate().first.widget.key! as ValueKey<String>).value, 'chat-2');

    await tester.longPress(find.byKey(const ValueKey('chat-2')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rename chat'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Chat name'), '  ');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
    expect(find.text('Give the chat a name.'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextFormField, 'Chat name'), 'Laptop plan');
    await tester.pumpAndSettle();
    expect(find.text('Give the chat a name.'), findsNothing, reason: 'clears as soon as it is fixed');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
    expect(find.text('Laptop plan'), findsOneWidget);
    final kept = (await world.coachChat.load()).firstWhere((t) => t.id == 2);
    expect((kept.title, kept.pinned), ('Laptop plan', true));
  });

  testWidgets('deleting a chat asks first, and Undo brings it back whole', (tester) async {
    final world = await openCoach(tester, open: false, seed: seedTwo);
    await tester.longPress(find.byKey(const ValueKey('chat-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete chat'));
    await tester.pumpAndSettle();
    expect(find.text('The coach forgets its 2 messages. Your entries, accounts and figures stay exactly as they are.'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('chat-1')), findsNothing);
    expect((await world.coachChat.load()).map((t) => t.id), [2]);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('chat-1')), findsOneWidget);
    expect((await world.coachChat.load()).firstWhere((t) => t.id == 1).messages, hasLength(2));
  });

  testWidgets("inside a chat its menu deletes it too, and goes back to the list", (tester) async {
    await openCoach(tester, seed: seedTwo);
    await tester.tap(find.descendant(of: chatPage, matching: find.byTooltip('More')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete chat'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(chatPage, findsNothing);
    expect(chatRows, findsOneWidget);
    expect(find.text('Chat deleted'), findsOneWidget);
  });

  testWidgets('a new chat shows no menu until something is asked in it', (tester) async {
    await openCoach(tester);
    expect(find.descendant(of: chatPage, matching: find.byTooltip('More')), findsNothing);
    await ask(tester, 'How did this week go?');
    expect(find.descendant(of: chatPage, matching: find.byTooltip('More')), findsOneWidget);
  });

  testWidgets('opening the tab, the chats rise in as the other tabs do, and the faces still follow the scroll', (tester) async {
    final day = DateTime(testToday.year, testToday.month, testToday.day, 9);
    await pumpApp(tester, seed: (w) {
      w.coachKeys.key = 'sk-ant-test-0123456789abcdefghij';
      w.coachChat.restore([for (var n = 1; n <= 3; n++) chatWith([said(true, 'Question $n', day)], id: n)]);
    });
    await tester.tap(find.byKey(const ValueKey('tab-Coach')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    final row = find.byKey(const ValueKey('chat-1'));
    final rising = tester.getTopLeft(row).dy;
    await tester.pumpAndSettle();
    expect(rising, greaterThan(tester.getTopLeft(row).dy), reason: 'it came up from below');
    expect(find.ancestor(of: row, matching: find.byType(ScrollAttention)), findsOneWidget);

    // Away and back: it rises in again.
    await tester.tap(find.byKey(const ValueKey('tab-Today')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('tab-Coach')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    final again = tester.getTopLeft(row).dy;
    await tester.pumpAndSettle();
    expect(again, greaterThan(tester.getTopLeft(row).dy));
  });
}
