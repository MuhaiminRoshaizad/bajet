import 'package:bajet/app/opening_overlay.dart';
import 'package:bajet/core/widgets/rise_in.dart';
import 'package:bajet/features/accounts/presentation/account_stack.dart';
import 'package:bajet/features/lock/domain/app_lock.dart';
import 'package:bajet/features/opening/presentation/opening_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/app_harness.dart';

void main() {
  final opening = [playOpeningProvider.overrideWithValue(true), initialEntranceHoldProvider.overrideWithValue(openingEntranceHold)];

  // Frame by frame, as a phone would draw it, so Today builds underneath.
  Future<void> play(WidgetTester tester, int ms) async {
    for (var t = 0; t < ms; t += 50) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  double stackOpacity(WidgetTester tester) =>
      tester.widget<Opacity>(find.ancestor(of: find.byType(AccountStack), matching: find.byType(Opacity)).first).opacity;

  testWidgets('the opening plays over Today, then hands it the stack', (tester) async {
    await pumpApp(tester, settle: false, overrides: (_) => opening);
    await play(tester, 1500);
    expect(find.byType(OpeningOverlay), findsOneWidget);
    expect(find.text('b'), findsOneWidget, reason: 'the wordmark is up');
    expect(stackOpacity(tester), 0, reason: "Today's own cards wait while the opening's fly");

    await play(tester, 1500);
    await tester.pumpAndSettle();
    expect(find.byType(OpeningOverlay), findsNothing);
    expect(stackOpacity(tester), 1);
  });

  testWidgets('a tap skips straight to Today', (tester) async {
    await pumpApp(tester, settle: false, overrides: (_) => opening);
    await play(tester, 400);
    await tester.tapAt(const Offset(180, 400));
    await tester.pumpAndSettle();
    expect(find.byType(OpeningOverlay), findsNothing);
    expect(stackOpacity(tester), 1);
    await play(tester, 3000);
  });

  testWidgets('with the lock on, the fingerprint is asked for only once the cards have landed', (tester) async {
    final world = await pumpApp(tester, settle: false, seed: (w) => w.lockSettings.saved = const LockSettings(enabled: true), overrides: (_) => opening);
    await play(tester, 2000);
    expect(world.deviceAuth.titles, isEmpty);
    await play(tester, 1000);
    await tester.pumpAndSettle();
    expect(world.deviceAuth.titles, ['Unlock bajet']);
    await play(tester, 3000);
  });

  testWidgets('with remove animations on, it does not play', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await pumpApp(tester, settle: false, overrides: (_) => opening);
    await tester.pump();
    await tester.pump();
    expect(find.byType(OpeningOverlay), findsNothing);
    expect(stackOpacity(tester), 1);
  });
}
