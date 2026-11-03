import 'dart:async';

import 'package:bajet/core/theme/app_theme.dart';
import 'package:bajet/features/coach/presentation/thinking_sphere.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'coach_screen_test.dart' show openCoach;

/// The button while it is the sphere.
final sphere = find.byWidgetPredicate((w) => w is Semantics && w.properties.value == 'waiting for the coach');

/// The arrow's visibility: the opacity drawn over it.
double arrow(WidgetTester tester) =>
    tester.widget<Opacity>(find.descendant(of: find.byType(ThinkingSendButton), matching: find.byType(Opacity))).opacity;

Future<void> pumpButton(WidgetTester tester, {required bool thinking}) => tester.pumpWidget(MaterialApp(
      theme: AppTheme.dark(),
      home: Scaffold(body: Center(child: ThinkingSendButton(thinking: thinking, onSend: () {}))),
    ));

void main() {
  testWidgets('while the coach answers the send button is its sphere, and the arrow springs back with the reply', (tester) async {
    final world = await openCoach(tester);
    world.coach.hold = Completer();
    await tester.enterText(find.byType(TextField), 'How did this week go?');
    await tester.tap(find.byTooltip('Send'));
    // The spring's clock starts on the frame after the send.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(sphere, findsOneWidget);
    expect(arrow(tester), 0, reason: 'the arrow has folded away');
    expect(tester.hasRunningAnimations, isTrue, reason: 'the sphere turns while the coach works');

    // A tap on the sphere sends nothing more.
    await tester.tap(find.byType(ThinkingSendButton));
    await tester.pump(const Duration(milliseconds: 100));
    expect(world.coach.requests, hasLength(1));

    world.coach.hold!.complete();
    world.coach.hold = null;
    await tester.pumpAndSettle();
    expect(sphere, findsNothing);
    expect(arrow(tester), 1);
    expect(find.text('You are on track.'), findsOneWidget);
  });

  testWidgets('with animations off the sphere stands still', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await pumpButton(tester, thinking: true);
    await tester.pump();
    expect(sphere, findsOneWidget);
    expect(tester.hasRunningAnimations, isFalse);

    await pumpButton(tester, thinking: false);
    await tester.pump();
    expect(arrow(tester), 1, reason: 'back to the arrow at once');
    expect(tester.hasRunningAnimations, isFalse);
  });
}
