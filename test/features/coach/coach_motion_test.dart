import 'dart:async';

import 'package:bajet/features/coach/domain/coach_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_repositories.dart' show chatWith;
import 'coach_screen_test.dart' show ask, openCoach;

/// How large the bubble holding [text] is drawn, against its laid-out size.
double drawnScale(WidgetTester tester, String text) {
  var scale = 1.0;
  for (final t in tester.widgetList<Transform>(find.ancestor(of: find.text(text), matching: find.byType(Transform)))) {
    scale *= t.transform.storage[0];
  }
  return scale;
}

void main() {
  testWidgets('a new question springs in from below, passes its size and settles', (tester) async {
    await openCoach(tester);
    await tester.enterText(find.byType(TextField), 'How did this week go?');
    await tester.tap(find.byTooltip('Send'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    expect(drawnScale(tester, 'How did this week go?'), lessThan(0.8));
    var most = 0.0;
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      final now = drawnScale(tester, 'How did this week go?');
      if (now > most) most = now;
    }
    expect(most, greaterThan(1.0));
    await tester.pumpAndSettle();
    expect(drawnScale(tester, 'How did this week go?'), 1);
  });

  testWidgets('a remembered chat is already in place when the tab opens', (tester) async {
    await openCoach(tester, seed: (w) => w.coachChat.restore([
          chatWith([
            CoachMessage(fromUser: true, text: 'Old question', sentAt: DateTime(2026, 7, 1, 9), id: 1),
            CoachMessage(fromUser: false, text: 'Old answer', sentAt: DateTime(2026, 7, 1, 9), id: 2),
          ]),
        ]));
    await tester.pump();
    expect(drawnScale(tester, 'Old question'), 1);
    expect(drawnScale(tester, 'Old answer'), 1);
  });

  testWidgets('while it works, the coach shows dots and then what it is reading', (tester) async {
    final world = await openCoach(tester);
    world.coach
      ..hold = Completer()
      ..lookups.add(('bajet_period', {'period': 'month'}));
    await tester.enterText(find.byType(TextField), 'How did this week go?');
    await tester.tap(find.byTooltip('Send'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Thinking…'), findsOneWidget);
    expect(find.text('thinking…'), findsOneWidget, reason: 'the header says so too');

    // The first turn asks for the month; the second waits.
    final first = world.coach.hold!;
    world.coach.hold = Completer();
    first.complete();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.textContaining('Looking at: '), findsOneWidget);

    final second = world.coach.hold!;
    world.coach.hold = null;
    second.complete();
    await tester.pumpAndSettle();
    expect(find.textContaining('Looking at: '), findsNothing);
    expect(find.text('Thinking…'), findsNothing);
    expect(find.text('You are on track.'), findsOneWidget);
    expect(world.coach.requests, hasLength(2));
  });

  testWidgets('with animations off, a new message is simply there', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await openCoach(tester);
    await tester.enterText(find.byType(TextField), 'How did this week go?');
    await tester.tap(find.byTooltip('Send'));
    await tester.pump();
    await tester.pump();
    expect(drawnScale(tester, 'How did this week go?'), 1);
    await ask(tester, 'And last week?');
  });
}
