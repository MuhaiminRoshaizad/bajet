import 'package:bajet/core/database/database_provider.dart';
import 'package:bajet/core/dates/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Shows today's day of the month, read the way every screen reads it.
Future<void> showToday(WidgetTester tester, DateTime Function() clock) => tester.pumpWidget(ProviderScope(
      overrides: [clockProvider.overrideWithValue(clock)],
      child: MaterialApp(home: Consumer(builder: (_, ref, _) => Text('day ${ref.watch(todayProvider).day}'))),
    ));

Future<void> backgroundAndResume(WidgetTester tester) async {
  for (final s in [AppLifecycleState.inactive, AppLifecycleState.hidden, AppLifecycleState.paused, AppLifecycleState.hidden, AppLifecycleState.inactive, AppLifecycleState.resumed]) {
    tester.binding.handleAppLifecycleStateChanged(s);
  }
  await tester.pump();
}

void main() {
  testWidgets('today moves on at midnight while the app stays open', (tester) async {
    var now = DateTime(2026, 10, 18, 23, 59);
    await showToday(tester, () => now);
    expect(find.text('day 18'), findsOneWidget);

    now = DateTime(2026, 10, 19, 0, 0, 1);
    await tester.pump(const Duration(minutes: 1, seconds: 1));
    await tester.pump();
    expect(find.text('day 19'), findsOneWidget);
  });

  testWidgets('today is read again when the app comes back from the background', (tester) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    var now = DateTime(2026, 10, 18, 22);
    await showToday(tester, () => now);

    now = DateTime(2026, 10, 18, 23);
    await backgroundAndResume(tester);
    expect(find.text('day 18'), findsOneWidget);

    // Asleep in the background past midnight, its timer frozen with it.
    now = DateTime(2026, 10, 19, 8);
    await backgroundAndResume(tester);
    await tester.pump();
    expect(find.text('day 19'), findsOneWidget);
  });
}
