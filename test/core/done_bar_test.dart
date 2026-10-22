import 'package:bajet/core/theme/app_theme.dart';
import 'package:bajet/core/widgets/done_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<ScaffoldMessengerState> pumpPage(WidgetTester tester) async {
  await tester.pumpWidget(MaterialApp(theme: AppTheme.light(), home: const Scaffold(body: SizedBox.expand())));
  return tester.state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger));
}

/// The bar's offset below where it rests, and its line's share of the width.
(double, double) motion(WidgetTester tester) {
  final rise = tester.widget<Transform>(find.descendant(of: find.byType(SnackBar), matching: find.byType(Transform)).first).transform.getTranslation().y;
  final line = tester.widget<FractionallySizedBox>(find.descendant(of: find.byType(SnackBar), matching: find.byType(FractionallySizedBox))).widthFactor!;
  return (rise, line);
}

void main() {
  testWidgets('a bar springs up, its line runs down over five seconds, then it slides away', (tester) async {
    final messenger = await pumpPage(tester);
    showBar(messenger, 'Saved MacBook', undo: () {});
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    expect(motion(tester).$1, greaterThan(10), reason: 'it starts below where it rests');
    var passed = false;
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      if (motion(tester).$1 < -0.5) passed = true;
    }
    expect(passed, isTrue, reason: 'it springs a little past its place');

    await tester.pump(const Duration(seconds: 2));
    expect(motion(tester).$2, closeTo(0.5, 0.1), reason: 'half the time left');
    expect(find.text('Saved MacBook'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 2600));
    await tester.pump(const Duration(milliseconds: 100));
    expect(motion(tester).$1, greaterThan(0), reason: 'sliding down on its way out');
    await tester.pumpAndSettle();
    expect(find.text('Saved MacBook'), findsNothing);
  });

  testWidgets('a newer bar replaces the one showing at once, and Undo runs and sends it away', (tester) async {
    final messenger = await pumpPage(tester);
    var undone = 0;
    showBar(messenger, 'Logged Coffee RM6.50');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    showBar(messenger, 'Logged Bus RM2.00', undo: () => undone++);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Logged Coffee RM6.50'), findsNothing);
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(undone, 1);
    expect(find.text('Logged Bus RM2.00'), findsNothing);
  });

  testWidgets('another choice can stand in for Undo', (tester) async {
    final messenger = await pumpPage(tester);
    var used = false;
    showBar(messenger, 'bajety pairs well with Sees Everything', action: ('Use it', () => used = true));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Undo'), findsNothing);
    await tester.tap(find.text('Use it'));
    expect(used, isTrue);
  });

  testWidgets('with TalkBack on, a bar with a choice waits to be dismissed', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(accessibleNavigation: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final messenger = await pumpPage(tester);
    showBar(messenger, 'Deleted Lunch', undo: () {});
    await tester.pump(const Duration(seconds: 8));
    expect(find.text('Deleted Lunch'), findsOneWidget);
  });
}
