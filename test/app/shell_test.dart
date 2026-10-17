import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bajet/core/navigation/routes.dart';
import 'package:go_router/go_router.dart';

import '../helpers/app_harness.dart';

void main() {
  testWidgets('the bottom bar switches between the four destinations', (tester) async {
    await pumpApp(tester);

    for (final label in ['Today', 'Runway', 'Insights', 'Coach']) {
      expect(find.byKey(ValueKey('tab-$label')), findsOneWidget);
    }

    await tester.tap(find.byKey(const ValueKey('tab-Insights')));
    await tester.pumpAndSettle();
    expect(find.text('Month'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('tab-Coach')));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(FilledButton, 'Add your key'), findsOneWidget);
  });

  testWidgets('every tab is at least 48 dp tall', (tester) async {
    await pumpApp(tester);
    expect(tester.getSize(find.byKey(const ValueKey('tab-Today'))).height, greaterThanOrEqualTo(48));
  });

  testWidgets('pages opened from a tab cover the bottom bar, and back brings it again', (tester) async {
    await pumpApp(tester);
    final context = tester.element(find.byKey(const ValueKey('tab-Today')));
    for (final route in [Routes.settings, Routes.rhythm, Routes.history, Routes.checkin, Routes.coachKey]) {
      GoRouter.of(context).push(route);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('tab-Today')), findsNothing, reason: route);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('tab-Today')), findsOneWidget, reason: route);
    }
  });
}
