import 'package:bajet/features/coach/domain/coach_answer.dart';
import 'package:bajet/features/coach/domain/coach_bursts.dart';
import 'package:bajet/features/coach/domain/coach_client.dart';
import 'package:bajet/features/coach/domain/coach_lookups.dart';
import 'package:bajet/features/coach/presentation/coach_chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_repositories.dart';
import 'coach_screen_test.dart' show openCoach, testKey;

void main() {
  test('a reply splits at each mark into at most three messages, dropping empty ones', () {
    expect(bursts('wah RM172.40 already\n<next>\nfood is most of it'), ['wah RM172.40 already', 'food is most of it']);
    expect(bursts('one thing only'), ['one thing only']);
    expect(bursts('a\n<next>\n\n<next>\nb'), ['a', 'b']);
    expect(bursts('a\n<next>\nb\n<next>\nc\n<next>\nd'), ['a', 'b', 'c\n\nd']);
    expect(joinBursts(['a', 'b']), 'a\n<next>\nb');
  });

  test('typing takes longer for a longer message, from half a second to two', () {
    expect(typingPause('ok'), const Duration(milliseconds: 500));
    expect(typingPause('x' * 40), const Duration(milliseconds: 1200));
    expect(typingPause('x' * 500), const Duration(seconds: 2));
  });

  test('a reply sent as several messages goes back to the coach as the one it wrote', () async {
    final coach = FakeCoach();
    await coachAnswer(
      client: coach,
      apiKey: testKey,
      system: 'Be brief.',
      conversation: const [
        CoachMessage(fromUser: true, text: 'how was my week'),
        CoachMessage(fromUser: false, text: 'RM22.40 over'),
        CoachMessage(fromUser: false, text: 'food is most of it'),
        CoachMessage(fromUser: true, text: 'ok what now'),
      ],
      tools: coachLookups,
      lookup: (name, _) => LookupResult('', name),
    );
    final sent = coach.requests.single.messages;
    expect([for (final m in sent) m['role']], ['user', 'assistant', 'user']);
    expect(sent[1]['content'], 'RM22.40 over\n<next>\nfood is most of it');
  });

  testWidgets('the coach texts its reply as messages in a row, typing before each, and a tap brings the rest', (tester) async {
    final world = await openCoach(tester);
    world.coach.reply = 'wah RM172.40 already this week\n<next>\nfood is RM96.10 of it\n<next>\ncook at home till sunday, ok ke?';
    world.coach.lookups.add(('bajet_overview', const {}));
    await tester.enterText(find.byType(TextField), "how's my week");
    await tester.tap(find.byTooltip('Send'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('wah RM172.40 already this week'), findsOneWidget);
    expect(find.text('food is RM96.10 of it'), findsNothing);
    expect(find.text('typing…'), findsOneWidget);
    expect(find.bySemanticsLabel('The coach is typing'), findsOneWidget);
    expect(find.textContaining('Looked at'), findsNothing, reason: 'what it looked at goes on the last message');

    // Half way through the second message's typing, it is not there yet.
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('food is RM96.10 of it'), findsNothing);
    await tester.pump(const Duration(milliseconds: 900));
    expect(find.text('food is RM96.10 of it'), findsOneWidget);

    // A tap on the chat brings the last one at once.
    await tester.tap(find.text('food is RM96.10 of it'));
    await tester.pump();
    await tester.pump();
    expect(find.text('cook at home till sunday, ok ke?'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('typing…'), findsNothing);
    expect(find.textContaining('Looked at'), findsOneWidget);
    final said = await world.coachChat.said();
    expect([for (final m in said) m.text], ["how's my week", 'wah RM172.40 already this week', 'food is RM96.10 of it', 'cook at home till sunday, ok ke?']);
    expect(find.byType(CoachChatScreen), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isTrue, reason: 'the box opens again once the reply is all there');
  });
}
