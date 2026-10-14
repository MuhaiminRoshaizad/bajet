import 'package:bajet/app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('the bottom bar switches between the four destinations', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: BajetApp()));
    await tester.pumpAndSettle();

    for (final label in ['Today', 'Runway', 'Insights', 'Coach']) {
      expect(find.byKey(ValueKey('tab-$label')), findsOneWidget);
    }

    await tester.tap(find.byKey(const ValueKey('tab-Insights')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Arrives in v1.1'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('tab-Coach')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Arrives in v1.3'), findsOneWidget);
  });

  testWidgets('every tab is at least 48 dp tall', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: BajetApp()));
    await tester.pumpAndSettle();
    final tab = tester.getSize(find.byKey(const ValueKey('tab-Today')));
    expect(tab.height, greaterThanOrEqualTo(48));
    expect(find.byType(InkResponse), findsNWidgets(4));
  });
}
