import 'package:bajet/core/platform/outside_app.dart';
import 'package:bajet/features/lock/data/file_lock_settings_store.dart';
import 'package:bajet/features/lock/domain/app_lock.dart';
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

  testWidgets('a phone with nothing left to check turns the lock off rather than locking the owner out', (tester) async {
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
}
