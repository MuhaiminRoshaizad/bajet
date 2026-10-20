import 'package:bajet/core/theme/app_theme.dart';
import 'package:bajet/features/coach/domain/coach_settings.dart';
import 'package:bajet/features/coach/presentation/coach_attention.dart';
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

  testWidgets('it glances where its attention looks, and wobbles once when nudged', (tester) async {
    final attention = CoachAttention();
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light(),
      home: Center(child: CoachAvatar(face: CoachFace.hafiz, size: 96, idle: false, attention: attention)),
    ));
    attention.lookAt(const Offset(0, 2));
    await tester.pumpAndSettle();
    expect((painter(tester).lookY as Animation<double>).value, closeTo(2, 0.01));

    attention.wobble(0.4);
    await tester.pump();
    expect((painter(tester).jelly as Animation<double>).value, lessThan(0.7), reason: 'squashed by the nudge');
    await tester.pumpAndSettle();
    expect((painter(tester).jelly as Animation<double>).value, 1);
  });

  testWidgets('a flung list turns the faces its way, then they look ahead and wobble', (tester) async {
    final attention = CoachAttention();
    await tester.pumpWidget(MaterialApp(
      home: ScrollAttention(
        attention: attention,
        child: ListView(children: [for (var i = 0; i < 60; i++) SizedBox(height: 80, child: Text('row $i'))]),
      ),
    ));
    await tester.fling(find.byType(ListView), const Offset(0, -600), 3000);
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 16));
    expect(attention.look.dy, greaterThan(0), reason: 'looking down the list as it moves down');
    await tester.pumpAndSettle();
    expect(attention.look, Offset.zero);
    expect(attention.nudges, 1);
  });

  testWidgets('with animations off it never glances', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final attention = CoachAttention();
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light(),
      home: Center(child: CoachAvatar(face: CoachFace.mei, size: 96, idle: false, attention: attention)),
    ));
    attention.lookAt(const Offset(0, 2));
    await tester.pumpAndSettle();
    expect((painter(tester).lookY as Animation<double>).value, 0);
  });
}
