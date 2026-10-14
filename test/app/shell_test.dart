import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/app_harness.dart';

void main() {
  testWidgets('the bottom bar switches between the four destinations', (tester) async {
    await pumpApp(tester);

    for (final label in ['Today', 'Runway', 'Insights', 'Coach']) {
      expect(find.byKey(ValueKey('tab-$label')), findsOneWidget);
    }

    await tester.tap(find.byKey(const ValueKey('tab-Insights')));
    await tester.pumpAndSettle();
    expect(find.text('This month'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('tab-Coach')));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(FilledButton, 'Add your key'), findsOneWidget);
  });

  testWidgets('every tab is at least 48 dp tall', (tester) async {
    await pumpApp(tester);
    expect(tester.getSize(find.byKey(const ValueKey('tab-Today'))).height, greaterThanOrEqualTo(48));
  });
}
