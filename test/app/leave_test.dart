import 'package:bajet/app/leave_guard.dart';
import 'package:bajet/features/lock/domain/app_lock.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/app_harness.dart';

void main() {
  late List<String> calls;
  setUp(() => calls = []);

  Future<void> pumpWithExit(WidgetTester tester, {LockSettings lock = const LockSettings()}) async {
    await pumpApp(tester, seed: (w) => w.lockSettings.saved = lock);
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      calls.add(call.method);
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
    // The lock screen, if the lock is on, is out of the way for these tests.
    await tester.pumpAndSettle();
  }

  Future<void> back(WidgetTester tester) async {
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
  }

  testWidgets('Back on another tab goes to Today instead of closing bajet', (tester) async {
    await pumpWithExit(tester);
    await tester.tap(find.byKey(const ValueKey('tab-Runway')));
    await tester.pumpAndSettle();
    await back(tester);
    expect(find.text('Leave bajet?'), findsNothing);
    expect(find.byTooltip('Settings'), findsOneWidget, reason: "Today's gear is back");
    expect(calls, isNot(contains('SystemNavigator.pop')));
  });

  testWidgets('Back on Today asks; Stay stays and Leave closes the app', (tester) async {
    await pumpWithExit(tester);
    await back(tester);
    expect(find.text('Leave bajet?'), findsOneWidget);
    expect(find.text("Everything you've logged is saved."), findsOneWidget);
    await tester.tap(find.text('Stay'));
    await tester.pumpAndSettle();
    expect(calls, isNot(contains('SystemNavigator.pop')));

    await back(tester);
    await tester.tap(find.text('Leave'));
    await tester.pumpAndSettle();
    expect(calls, contains('SystemNavigator.pop'));
  });

  testWidgets('Back inside a screen still just goes back', (tester) async {
    await pumpWithExit(tester);
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await back(tester);
    expect(find.text('Leave bajet?'), findsNothing);
    expect(find.byTooltip('Settings'), findsOneWidget);
  });

  test('the App lock line follows the user\'s setting', () {
    expect(leaveLockLine(const LockSettings()), isNull);
    expect(leaveLockLine(const LockSettings(enabled: true, grace: LockGrace.immediately)), "App lock is on, so you'll need your fingerprint to get back in.");
    expect(leaveLockLine(const LockSettings(enabled: true, grace: LockGrace.fiveMinutes)), "If you're away for more than 5 minutes, you'll need your fingerprint to get back in.");
  });
}
