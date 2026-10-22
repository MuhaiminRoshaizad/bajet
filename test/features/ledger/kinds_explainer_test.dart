import 'package:bajet/core/storage/device_flags.dart';
import 'package:bajet/features/lock/domain/app_lock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/app_harness.dart';

void main() {
  testWidgets('the explainer opens once on a phone that has not seen it, and the quick check answers', (tester) async {
    final world = await pumpApp(tester, seed: (w) => w.flags.on.clear());
    expect(find.text('Not all spending is a choice'), findsOneWidget);
    expect(world.flags.on, contains(DeviceFlag.kindsExplained));

    await tester.tap(find.byKey(const ValueKey('check-want')));
    await tester.pumpAndSettle();
    expect(find.text("Not quite: you'd have bought it anyway, so it is a need."), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('check-need')));
    await tester.pumpAndSettle();
    expect(find.text("Right: you'd have bought it anyway."), findsOneWidget);

    await tester.ensureVisible(find.text('Got it'));
    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();
    expect(find.text('Not all spending is a choice'), findsNothing);
  });

  testWidgets("a phone that has seen it opens it only from What's this?", (tester) async {
    await pumpApp(tester);
    expect(find.text('Not all spending is a choice'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('add')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text("What's this?"));
    await tester.tap(find.text("What's this?"));
    await tester.pumpAndSettle();
    expect(find.text('Not all spending is a choice'), findsOneWidget);
  });

  testWidgets('behind the lock, the explainer waits until the lock is passed', (tester) async {
    await pumpApp(tester, seed: (w) {
      w.flags.on.clear();
      w.lockSettings.saved = const LockSettings(enabled: true);
      w.deviceAuth.outcomes = [AuthOutcome.cancelled, AuthOutcome.passed];
    });
    expect(find.text('bajet is locked'), findsOneWidget);
    expect(find.text('Not all spending is a choice'), findsNothing);
    await tester.tap(find.bySemanticsLabel('Unlock with fingerprint'));
    await tester.pumpAndSettle();
    expect(find.text('Not all spending is a choice'), findsOneWidget);
  });
}
