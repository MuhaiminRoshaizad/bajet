import 'package:bajet/features/coach/domain/coach_client.dart';
import 'package:bajet/features/coach/domain/coach_settings.dart';
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
}
