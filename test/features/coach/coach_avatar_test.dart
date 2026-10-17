import 'package:bajet/core/theme/app_theme.dart';
import 'package:bajet/features/coach/domain/coach_settings.dart';
import 'package:bajet/features/coach/presentation/coach_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> pumpAvatar(WidgetTester tester, CoachFace face, CoachMood mood, {VoidCallback? onTap}) => tester.pumpWidget(MaterialApp(
      theme: AppTheme.light(),
      home: Center(child: CoachAvatar(face: face, mood: mood, size: 96, idle: false, onTap: onTap)),
    ));

/// The avatar's own painter, whose animations say how far through it is.
dynamic painter(WidgetTester tester) =>
    tester.widgetList<CustomPaint>(find.descendant(of: find.byType(CoachAvatar), matching: find.byType(CustomPaint))).first.painter;

void main() {
  testWidgets('every coach draws every mood, and says who it is', (tester) async {
    for (final face in CoachFace.values) {
      for (final mood in CoachMood.values) {
        await pumpAvatar(tester, face, mood);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$face $mood');
      }
      expect(find.bySemanticsLabel('${face.label}, your money coach'), findsOneWidget);
    }
  });

  testWidgets('a change of mood wobbles past its shape and settles back', (tester) async {
    await pumpAvatar(tester, CoachFace.bajety, CoachMood.idle);
    await tester.pumpAndSettle();
    await pumpAvatar(tester, CoachFace.bajety, CoachMood.happy);
    var most = 0.0;
    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      final jelly = (painter(tester).jelly as Animation<double>).value;
      if (jelly > most) most = jelly;
    }
    await tester.pumpAndSettle();
    expect(most, greaterThan(1.05), reason: 'the jelly overshoots before it settles');
    expect((painter(tester).jelly as Animation<double>).value, 1);
  });

  testWidgets('tapping it says hello, then it smiles again, and the tap is passed on', (tester) async {
    var taps = 0;
    await pumpAvatar(tester, CoachFace.aina, CoachMood.idle, onTap: () => taps++);
    await tester.tap(find.byType(CoachAvatar));
    await tester.pumpAndSettle();
    expect(taps, 1);
    expect((painter(tester).hop as Animation<double>).value, 1);
  });

  testWidgets('with animations off it changes mood without moving', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await pumpAvatar(tester, CoachFace.mei, CoachMood.idle);
    await pumpAvatar(tester, CoachFace.mei, CoachMood.concerned);
    await tester.pump();
    expect((painter(tester).jelly as Animation<double>).isAnimating, isFalse);
    expect((painter(tester).morph as Animation<double>).value, 1);
  });
}
