import 'package:bajet/core/storage/device_flags.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/app_harness.dart';

/// A phone with Android's three-button navigation: 48 points across the
/// bottom that the app draws under, edge to edge.
const _bar = 48.0;

Future<void> withThreeButtons(WidgetTester tester) async {
  tester.view
    ..padding = const FakeViewPadding(bottom: _bar * 3)
    ..viewPadding = const FakeViewPadding(bottom: _bar * 3);
  addTearDown(tester.view.resetPadding);
  addTearDown(tester.view.resetViewPadding);
}

/// The bottom of [finder] is above the buttons.
void expectClearOfBar(WidgetTester tester, Finder finder) {
  final screen = tester.view.physicalSize.height / tester.view.devicePixelRatio;
  expect(tester.getRect(finder).bottom, lessThanOrEqualTo(screen - _bar), reason: '$finder sits under the navigation bar');
}

void main() {
  testWidgets("the log sheet's button stays above the navigation bar", (tester) async {
    await withThreeButtons(tester);
    await pumpApp(tester);
    await tester.tap(find.byKey(const ValueKey('add')));
    await tester.pumpAndSettle();
    expectClearOfBar(tester, find.widgetWithText(FilledButton, 'Type the amount'));
  });

  testWidgets("the explainer's button stays above the navigation bar", (tester) async {
    await withThreeButtons(tester);
    await pumpApp(tester, seed: (w) => w.flags.on.remove(DeviceFlag.kindsExplained));
    await tester.ensureVisible(find.text('Got it'));
    await tester.pumpAndSettle();
    expectClearOfBar(tester, find.widgetWithText(FilledButton, 'Got it'));
  });

  testWidgets("a settings sheet's Save stays above the navigation bar", (tester) async {
    await withThreeButtons(tester);
    await pumpApp(tester);
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Your name'));
    await tester.pumpAndSettle();
    expectClearOfBar(tester, find.widgetWithText(FilledButton, 'Save'));
  });
}
