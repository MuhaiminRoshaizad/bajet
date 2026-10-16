import 'package:bajet/features/lock/domain/app_lock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/app_harness.dart';

Future<void> openAppLock(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Settings'));
  await tester.pumpAndSettle();
  await tester.dragUntilVisible(find.text('App lock'), find.byType(ListView), const Offset(0, -200));
  await tester.pumpAndSettle();
  await tester.tap(find.text('App lock'));
  await tester.pumpAndSettle();
}

Finder get lockSwitch => find.widgetWithText(SwitchListTile, 'Lock with fingerprint');

void main() {
  testWidgets('turning the lock on asks for the fingerprint first, then offers the grace', (tester) async {
    final world = await pumpApp(tester);
    await openAppLock(tester);
    expect(find.text('Ask again after'), findsNothing);
    await tester.tap(lockSwitch);
    await tester.pumpAndSettle();
    expect(world.deviceAuth.titles, ['Turn on App lock']);
    expect(world.lockSettings.saved, const LockSettings(enabled: true));

    await tester.tap(find.text('5 minutes'));
    await tester.pumpAndSettle();
    expect(world.lockSettings.saved.grace, LockGrace.fiveMinutes);
    await tester.tapAt(const Offset(180, 40));
    await tester.pumpAndSettle();
    expect(find.text('Fingerprint · after 5 minutes'), findsOneWidget);
  });

  testWidgets('a cancelled check leaves the lock off, and a failed one says so', (tester) async {
    final world = await pumpApp(tester, seed: (w) => w.deviceAuth.outcomes = [AuthOutcome.cancelled, AuthOutcome.failed]);
    await openAppLock(tester);
    await tester.tap(lockSwitch);
    await tester.pumpAndSettle();
    expect(world.lockSettings.saved.enabled, isFalse);
    expect(find.textContaining("couldn't check"), findsNothing);
    await tester.tap(lockSwitch);
    await tester.pumpAndSettle();
    expect(world.lockSettings.saved.enabled, isFalse);
    expect(find.textContaining("couldn't check it's you"), findsOneWidget);
  });

  testWidgets('a phone with no screen lock cannot turn it on, and says what to do', (tester) async {
    final world = await pumpApp(tester, seed: (w) => w.deviceAuth.available = false);
    await openAppLock(tester);
    expect(find.textContaining('Your phone has no screen lock.'), findsOneWidget);
    await tester.tap(lockSwitch);
    await tester.pumpAndSettle();
    expect(world.deviceAuth.titles, isEmpty);
  });

  testWidgets('turning it off needs no check', (tester) async {
    final world = await pumpApp(tester, seed: (w) => w.lockSettings.saved = const LockSettings(enabled: true));
    await openAppLock(tester);
    await tester.tap(lockSwitch);
    await tester.pumpAndSettle();
    expect(world.lockSettings.saved.enabled, isFalse);
    expect(world.deviceAuth.titles, ['Unlock bajet'], reason: 'only the unlock on opening');
  });
}
