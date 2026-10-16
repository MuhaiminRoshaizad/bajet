import 'package:bajet/app/opening_overlay.dart';
import 'package:bajet/core/widgets/rise_in.dart';
import 'package:bajet/features/accounts/presentation/account_stack.dart';
import 'package:bajet/features/lock/domain/app_lock.dart';
import 'package:bajet/features/opening/domain/opening_timeline.dart';
import 'package:bajet/features/opening/presentation/opening_providers.dart';
import 'package:bajet/features/opening/presentation/titanium_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/app_harness.dart';

void main() {
  final opening = [playOpeningProvider.overrideWithValue(true), initialEntranceHoldProvider.overrideWithValue(true)];

  // Frame by frame, as a phone would draw it, so Today builds underneath.
  Future<void> play(WidgetTester tester, int ms) async {
    for (var t = 0; t < ms; t += 50) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  double stackOpacity(WidgetTester tester) =>
      tester.widget<Opacity>(find.ancestor(of: find.byType(AccountStack), matching: find.byType(Opacity)).first).opacity;

  testWidgets("bajet picks the fan up where Android's splash left it, then hands Today the stack", (tester) async {
    final world = await pumpApp(tester, settle: false, overrides: (_) => opening);
    await play(tester, 300);
    expect(world.splash.removed, isTrue, reason: 'Android lets go once bajet draws the same fan');
    expect(find.byType(TitaniumCard), findsNWidgets(3));
    expect(find.text('b'), findsOneWidget, reason: 'the wordmark is up, as Android left it');
    expect(stackOpacity(tester), 0, reason: "Today's own cards wait while the opening's fly");

    await play(tester, 1000);
    await tester.pumpAndSettle();
    expect(find.byType(OpeningOverlay), findsNothing);
    expect(stackOpacity(tester), 1);
  });

  testWidgets('without an animated splash, as before Android 12, bajet deals the cards itself, centred', (tester) async {
    // Android can also draw the first frame before it reports the screen's size.
    final world = await pumpApp(tester, settle: false, seed: (w) {
      w.splash.played = false;
      tester.view.physicalSize = Size.zero;
    }, overrides: (_) => opening);
    await tester.pump();
    tester.view.physicalSize = const Size(1080, 2340);
    await play(tester, 450);
    final front = tester.getCenter(find.byType(TitaniumCard).last);
    expect(front.dx, closeTo(180, .5));
    expect(front.dy, closeTo(780 / 2 - 20 * OpeningPlan.zoom - 1.85 * OpeningPlan.k, .5));
    expect(world.splash.removed, isTrue);
    await play(tester, 2500);
  });

  testWidgets('a tap skips straight to Today', (tester) async {
    await pumpApp(tester, settle: false, overrides: (_) => opening);
    await play(tester, 200);
    await tester.tapAt(const Offset(180, 400));
    await tester.pumpAndSettle();
    expect(find.byType(OpeningOverlay), findsNothing);
    expect(stackOpacity(tester), 1);
  });

  testWidgets('with the lock on, the fingerprint is asked for only once the cards have landed', (tester) async {
    final world = await pumpApp(tester, settle: false, seed: (w) => w.lockSettings.saved = const LockSettings(enabled: true), overrides: (_) => opening);
    await play(tester, 400);
    expect(world.deviceAuth.titles, isEmpty);
    await play(tester, 1000);
    await tester.pumpAndSettle();
    expect(world.deviceAuth.titles, ['Unlock bajet']);
  });

  testWidgets('with remove animations on, it does not play', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await pumpApp(tester, settle: false, overrides: (_) => opening);
    await play(tester, 300);
    expect(find.byType(OpeningOverlay), findsNothing);
    expect(stackOpacity(tester), 1);
    expect(find.byType(OpeningOverlay), findsNothing);
  });
}
