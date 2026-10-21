import 'package:bajet/core/platform/outside_app.dart';
import 'package:bajet/features/accounts/presentation/account_stack.dart';
import 'package:bajet/features/coach/presentation/coach_screen.dart';
import 'package:bajet/features/lock/data/file_lock_settings_store.dart';
import 'package:bajet/features/lock/domain/app_lock.dart';
import 'package:bajet/features/opening/presentation/flying_card.dart';
import 'package:bajet/features/today/presentation/today_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/fake_repositories.dart';

void main() {
  test('settings round-trip, and anything unreadable leaves the lock off', () {
    for (final s in [const LockSettings(), const LockSettings(enabled: true, grace: LockGrace.immediately)]) {
      expect(FileLockSettingsStore.parse(FileLockSettingsStore.format(s)), s);
    }
    expect(FileLockSettingsStore.parse(''), const LockSettings());
    expect(FileLockSettingsStore.parse('on nonsense'), const LockSettings(enabled: true));
  });

  Future<FakeWorld> pumpLocked(WidgetTester tester, {List<AuthOutcome> outcomes = const [AuthOutcome.passed], LockGrace grace = LockGrace.oneMinute}) =>
      pumpApp(tester, seed: (w) {
        w.lockSettings.saved = LockSettings(enabled: true, grace: grace);
        w.deviceAuth.outcomes = [...outcomes];
      });

  Future<void> leave(WidgetTester tester) async {
    for (final s in [AppLifecycleState.inactive, AppLifecycleState.hidden, AppLifecycleState.paused]) {
      tester.binding.handleAppLifecycleStateChanged(s);
    }
    await tester.pump();
  }

  Future<void> comeBack(WidgetTester tester) async {
    for (final s in [AppLifecycleState.hidden, AppLifecycleState.inactive, AppLifecycleState.resumed]) {
      tester.binding.handleAppLifecycleStateChanged(s);
    }
    await tester.pumpAndSettle();
  }

  testWidgets('with the lock off, the app opens straight on Today', (tester) async {
    final world = await pumpApp(tester);
    expect(find.text('bajet is locked'), findsNothing);
    expect(world.deviceAuth.titles, isEmpty);
  });

  testWidgets('with the lock on, the app asks at once and opens once it passes', (tester) async {
    final world = await pumpLocked(tester);
    expect(world.deviceAuth.titles, ['Unlock bajet']);
    expect(find.text('bajet is locked'), findsNothing);
    expect(find.text('Today'), findsWidgets);
  });

  testWidgets('a cancelled prompt leaves the lock up until asked again', (tester) async {
    final world = await pumpLocked(tester, outcomes: [AuthOutcome.cancelled, AuthOutcome.passed]);
    expect(find.text('bajet is locked'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Unlock with fingerprint'));
    await tester.pumpAndSettle();
    expect(find.text('bajet is locked'), findsNothing);
    expect(world.deviceAuth.titles, hasLength(2));
  });

  testWidgets('a wrong finger and a lockout each say what to do next', (tester) async {
    await pumpLocked(tester, outcomes: [AuthOutcome.failed, AuthOutcome.lockedOut]);
    expect(find.text("That didn't work. Try again, or use your phone PIN."), findsOneWidget);
    await tester.tap(find.text('Use phone PIN instead'));
    await tester.pumpAndSettle();
    expect(find.text('Fingerprint paused'), findsOneWidget);
    expect(find.bySemanticsLabel('Unlock with fingerprint'), findsNothing);
    expect(find.text('Use phone PIN'), findsOneWidget);
  });

  testWidgets('a phone with nothing left to check turns the lock off rather than locking the user out', (tester) async {
    final world = await pumpLocked(tester, outcomes: [AuthOutcome.unavailable]);
    expect(find.text('App lock is off'), findsOneWidget);
    await tester.tap(find.text('Open bajet'));
    await tester.pumpAndSettle();
    expect(find.text('App lock is off'), findsNothing);
    expect(world.lockSettings.saved.enabled, isFalse);
  });

  testWidgets('coming back within the grace stays open; longer away locks again', (tester) async {
    final world = await pumpLocked(tester);
    await leave(tester);
    world.clock = world.clock.add(const Duration(seconds: 40));
    await comeBack(tester);
    expect(world.deviceAuth.titles, hasLength(1));

    await leave(tester);
    world.clock = world.clock.add(const Duration(minutes: 2));
    world.deviceAuth.outcomes = [AuthOutcome.cancelled];
    await comeBack(tester);
    expect(find.text('bajet is locked'), findsOneWidget);
    expect(world.deviceAuth.titles, hasLength(2));
  });

  testWidgets('straight away locks on any return', (tester) async {
    final world = await pumpLocked(tester, outcomes: [AuthOutcome.passed, AuthOutcome.cancelled], grace: LockGrace.immediately);
    await leave(tester);
    await comeBack(tester);
    expect(find.text('bajet is locked'), findsOneWidget);
    expect(world.deviceAuth.titles, hasLength(2));
  });

  testWidgets("time in a screen bajet opened itself, such as the camera, doesn't count", (tester) async {
    final world = await pumpLocked(tester, grace: LockGrace.immediately);
    await OutsideApp.run(() async {
      await leave(tester);
      world.clock = world.clock.add(const Duration(minutes: 3));
      await comeBack(tester);
    });
    expect(find.text('bajet is locked'), findsNothing);
    expect(world.deviceAuth.titles, hasLength(1));
  });

  double stackOpacity(WidgetTester tester) =>
      tester.widget<Opacity>(find.ancestor(of: find.byType(AccountStack), matching: find.byType(Opacity)).first).opacity;

  testWidgets("unlocking flies the lock screen's fan into Today's stack", (tester) async {
    await pumpLocked(tester, outcomes: [AuthOutcome.cancelled, AuthOutcome.passed]);
    await tester.tap(find.bySemanticsLabel('Unlock with fingerprint'));
    for (var t = 0; t < 400; t += 50) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.byType(FlyingCard), findsNWidgets(3));
    expect(tester.widgetList<FlyingCard>(find.byType(FlyingCard)).every((c) => c.face != null), isTrue, reason: 'they land as the real cards');
    expect(stackOpacity(tester), 0, reason: "Today's own cards wait while the fan's fly");
    await tester.pumpAndSettle();
    expect(find.text('bajet is locked'), findsNothing);
    expect(find.byType(FlyingCard), findsNothing);
    expect(stackOpacity(tester), 1);
  });

  testWidgets("the flying cards' faces are drawn in the app's text style", (tester) async {
    await pumpLocked(tester, outcomes: [AuthOutcome.cancelled, AuthOutcome.passed]);
    await tester.tap(find.bySemanticsLabel('Unlock with fingerprint'));
    for (var t = 0; t < 600; t += 50) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    // Without a Material above them, text falls back to Flutter's unstyled
    // look: yellow double underlines in a monospace face.
    expect(find.ancestor(of: find.byType(FlyingCard).first, matching: find.byType(Material)), findsWidgets);
    await tester.pumpAndSettle();
  });

  testWidgets("on a cold start the fan lands where Today's stack ends up, not where it was sliding in", (tester) async {
    await pumpLocked(tester, outcomes: [AuthOutcome.cancelled, AuthOutcome.passed]);
    await tester.tap(find.bySemanticsLabel('Unlock with fingerprint'));
    // Just before the cards hand over to the real stack.
    for (var t = 0; t < 860; t += 20) {
      await tester.pump(const Duration(milliseconds: 20));
    }
    final front = tester.getRect(find.byType(FlyingCard).last);
    await tester.pumpAndSettle();
    final stack = tester.getRect(find.byType(AccountStack));
    expect(front.left, closeTo(stack.left, 2), reason: 'a card landing beside the stack would jump into place');
  });

  testWidgets('unlocking always opens on Today, wherever the lock came down', (tester) async {
    final world = await pumpLocked(tester);
    await tester.tap(find.byKey(const ValueKey('tab-Coach')));
    await tester.pumpAndSettle();
    expect(find.byType(CoachScreen), findsOneWidget);
    await leave(tester);
    world.clock = world.clock.add(const Duration(minutes: 2));
    world.deviceAuth.outcomes = [AuthOutcome.passed];
    await comeBack(tester);
    expect(find.byType(CoachScreen), findsNothing);
    expect(find.byType(TodayScreen), findsOneWidget);
  });

  testWidgets('with remove animations on, unlocking opens at once', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await pumpLocked(tester, outcomes: [AuthOutcome.cancelled, AuthOutcome.passed]);
    await tester.tap(find.bySemanticsLabel('Unlock with fingerprint'));
    await tester.pump();
    await tester.pump();
    expect(find.text('bajet is locked'), findsNothing);
    expect(find.byType(FlyingCard), findsNothing);
  });
}
