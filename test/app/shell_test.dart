import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bajet/core/navigation/routes.dart';
import 'package:bajet/features/today/presentation/today_screen.dart';
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

  testWidgets('each tab sits in the middle of the hollow', (tester) async {
    await pumpApp(tester);
    final hollow = tester.getCenter(find.byKey(const ValueKey('tab-hollow')));
    expect(tester.getCenter(find.byKey(const ValueKey('tab-Today'))).dy, moreOrLessEquals(hollow.dy, epsilon: 0.5));
  });

  testWidgets('the hollow under the open tab springs across to the next one', (tester) async {
    await pumpApp(tester);
    final hollow = find.byKey(const ValueKey('tab-hollow'));
    double gap(String tab) => (tester.getCenter(hollow).dx - tester.getCenter(find.byKey(ValueKey('tab-$tab'))).dx).abs();
    expect(gap('Today'), lessThan(1));

    await tester.tap(find.byKey(const ValueKey('tab-Insights')));
    await tester.pump(const Duration(milliseconds: 60));
    expect(gap('Insights'), greaterThan(1), reason: 'still on its way');
    await tester.pumpAndSettle();
    expect(gap('Insights'), lessThan(1));
  });

  testWidgets('springing to an end tab, the hollow squashes against the pill instead of leaving it', (tester) async {
    await pumpApp(tester);
    final hollow = find.byKey(const ValueKey('tab-hollow'));
    final pill = tester.getRect(find.ancestor(of: hollow, matching: find.byType(Stack)).first);
    final full = tester.getSize(hollow).width;

    for (final (tab, end) in [('Coach', 'right'), ('Today', 'left')]) {
      await tester.tap(find.byKey(ValueKey('tab-$tab')));
      var narrowest = full;
      for (var i = 0; i < 60; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        final r = tester.getRect(hollow);
        expect(r.left, greaterThanOrEqualTo(pill.left), reason: '$tab, $end');
        expect(r.right, lessThanOrEqualTo(pill.right), reason: '$tab, $end');
        if (r.width < narrowest) narrowest = r.width;
      }
      expect(narrowest, lessThan(full - 1), reason: 'it squashed at the $end end');
      await tester.pumpAndSettle();
      expect(tester.getSize(hollow).width, moreOrLessEquals(full), reason: 'and sprang back');
    }
  });

  testWidgets("a tab's list runs under the floating bar and ends clear of it", (tester) async {
    await pumpApp(tester);
    final bar = tester.getRect(find.byKey(const ValueKey('add')));
    final list = find.descendant(of: find.byType(TodayScreen), matching: find.byType(ListView));
    expect(tester.getRect(list).bottom, greaterThan(bar.bottom), reason: 'the page shows under and around the bar');
    final padding = tester.widget<ListView>(list).padding!.resolve(TextDirection.ltr);
    expect(tester.getRect(list).bottom - padding.bottom, lessThan(bar.top), reason: 'the last row scrolls clear of it');
    expect(padding.bottom, lessThan(bar.height * 2), reason: 'no more room than the bar needs');
  });
}
