import 'package:bajet/features/coach/domain/coach_settings.dart';
import 'package:bajet/features/coach/presentation/coach_avatar.dart';
import 'package:bajet/features/coach/presentation/coach_chats.dart';
import 'package:bajet/features/coach/presentation/coach_chat_screen.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_repositories.dart' show SaidMessages;
import 'coach_screen_test.dart' show ask, chatPage, openCoach;

Future<void> openChatSettings(WidgetTester tester) async {
  await tester.tap(find.bySemanticsLabel(RegExp("This chat's coach")));
  await tester.pumpAndSettle();
}

/// Closes the chat settings, as Back does.
Future<void> closeSheet(WidgetTester tester) async {
  Navigator.of(tester.element(find.text("This chat's coach"))).pop();
  await tester.pumpAndSettle();
}

/// The face at the top of the chat on screen.
CoachAvatar header(WidgetTester tester) => tester.widget<CoachAvatar>(find.descendant(of: chatPage, matching: find.byType(CoachAvatar)).first);

void main() {
  testWidgets('the header shows the coach, its personality, and a welcome until the first question', (tester) async {
    await openCoach(tester);
    expect(header(tester).face, CoachFace.bajety);
    expect(find.text('Friendly'), findsOneWidget);
    expect(find.text("Hi, I'm bajety."), findsOneWidget);
    await ask(tester, 'How did this week go?');
    expect(find.text("Hi, I'm bajety."), findsNothing);
    expect(header(tester).mood, CoachMood.happy);
  });

  testWidgets("switching this chat's coach keeps the chat, and the new face says hello in it", (tester) async {
    final world = await openCoach(tester);
    await ask(tester, 'How did this week go?');
    await openChatSettings(tester);
    expect(find.text("This chat's coach"), findsOneWidget);
    await tester.tap(find.text('Mei'));
    await tester.pumpAndSettle();
    await closeSheet(tester);

    expect((await world.coachChat.load()).single.face, CoachFace.mei);
    expect(world.coachSettings.value.face, CoachFace.bajety, reason: 'new chats still start with bajety');
    expect(find.text("Hi, Mei here. I've read our chat, so carry on."), findsOneWidget);
    expect(find.text('You are on track.'), findsOneWidget);
    // The earlier reply keeps the face that gave it.
    final said = await world.coachChat.said();
    expect(said[1].face, CoachFace.bajety);
    expect(said.last.face, CoachFace.mei);
  });

  testWidgets('picking bajety offers its knows-too-much voice', (tester) async {
    final world = await openCoach(tester, seed: (w) => w.coachSettings.saveSettings(const CoachSettings(face: CoachFace.hafiz)));
    await ask(tester, 'How did this week go?');
    await openChatSettings(tester);
    await tester.tap(find.text('bajety'));
    await tester.pumpAndSettle();
    await closeSheet(tester);
    expect(find.text('bajety pairs well with Sees Everything 😉'), findsOneWidget);
    await tester.tap(find.text('Use it'));
    await tester.pumpAndSettle();
    expect((await world.coachChat.load()).single.personality, CoachPersonality.seesEverything);
    expect(find.text('Sees Everything'), findsOneWidget);
  });

  testWidgets("a change of personality leaves a line in the chat, and the next answer has the new voice", (tester) async {
    final world = await openCoach(tester);
    await ask(tester, 'How did this week go?');
    await openChatSettings(tester);
    await tester.tap(find.text('Strict'));
    await tester.pumpAndSettle();
    await closeSheet(tester);
    expect(find.text('bajety is now Strict'), findsOneWidget);
    expect(find.descendant(of: chatPage, matching: find.text('Strict')), findsOneWidget);

    await ask(tester, 'And this month?');
    expect(world.coach.lastSystem, endsWith('Your voice: ${CoachPersonality.strict.voice}'));
    expect(world.coach.requests.last.messages.toString(), isNot(contains('is now Strict')), reason: 'a note is never sent');
  });

  testWidgets('a message turned away makes the coach concerned, and Sees Everything stare', (tester) async {
    final world = await openCoach(tester);
    world.coach.gateKind = 'off_topic';
    await ask(tester, 'Write me some code');
    expect(header(tester).mood, CoachMood.concerned);

    final app = ProviderScope.containerOf(tester.element(chatPage));
    await app.read(coachChatsProvider.notifier).setCoach(tester.widget<CoachChatScreen>(chatPage).chat, personality: CoachPersonality.seesEverything);
    await tester.pumpAndSettle();
    await ask(tester, 'Write me some more code');
    expect(header(tester).mood, CoachMood.stare);
    expect(find.textContaining('😉'), findsWidgets);
  });
}
