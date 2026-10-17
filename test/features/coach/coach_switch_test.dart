import 'package:bajet/features/coach/domain/coach_settings.dart';
import 'package:bajet/features/coach/presentation/coach_avatar.dart';
import 'package:flutter_test/flutter_test.dart';

import 'coach_screen_test.dart' show ask, openCoach;

/// The face in the Coach tab's header.
CoachAvatar header(WidgetTester tester) => tester.widget<CoachAvatar>(find.byType(CoachAvatar).first);

void main() {
  testWidgets('the header shows the coach, its personality, and a welcome until the first question', (tester) async {
    await openCoach(tester);
    expect(header(tester).face, CoachFace.bajety);
    expect(find.text('Friendly'), findsOneWidget);
    expect(find.text("Hi, I'm Bajety."), findsOneWidget);
    await ask(tester, 'How did this week go?');
    expect(find.text("Hi, I'm Bajety."), findsNothing);
    expect(header(tester).mood, CoachMood.happy);
  });

  testWidgets('switching coach keeps the chat, and the new face says hello in it', (tester) async {
    final world = await openCoach(tester);
    await ask(tester, 'How did this week go?');
    await tester.tap(find.bySemanticsLabel(RegExp('Switch coach')));
    await tester.pumpAndSettle();
    expect(find.text('Choose your coach'), findsOneWidget);
    await tester.tap(find.text('Mei'));
    await tester.pumpAndSettle();

    expect(world.coachSettings.value.face, CoachFace.mei);
    expect(find.text("Hi, Mei here. I've read our chat, so carry on."), findsOneWidget);
    expect(find.text('You are on track.'), findsOneWidget);
    // The earlier reply keeps the face that gave it.
    expect(world.coachChat.saved[1].face, CoachFace.bajety);
    expect(world.coachChat.saved.last.face, CoachFace.mei);
  });

  testWidgets('picking Bajety offers its knows-too-much voice', (tester) async {
    final world = await openCoach(tester, seed: (w) => w.coachSettings.saveSettings(const CoachSettings(face: CoachFace.hafiz)));
    await tester.tap(find.bySemanticsLabel(RegExp('Switch coach')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bajety'));
    await tester.pumpAndSettle();
    expect(find.text('Bajety pairs well with Sees Everything 😉'), findsOneWidget);
    await tester.tap(find.text('Use it'));
    await tester.pumpAndSettle();
    expect(world.coachSettings.value.personality, CoachPersonality.seesEverything);
    expect(find.text('Sees Everything'), findsOneWidget);
  });

  testWidgets('a message turned away makes the coach concerned, and Sees Everything stare', (tester) async {
    final world = await openCoach(tester);
    world.coach.gateKind = 'off_topic';
    await ask(tester, 'Write me some code');
    expect(header(tester).mood, CoachMood.concerned);

    await world.coachSettings.saveSettings(const CoachSettings(personality: CoachPersonality.seesEverything));
    await tester.pumpAndSettle();
    await ask(tester, 'Write me some more code');
    expect(header(tester).mood, CoachMood.stare);
    expect(find.textContaining('😉'), findsWidgets);
  });
}
