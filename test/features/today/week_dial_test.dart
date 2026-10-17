import 'package:bajet/core/database/database_provider.dart';
import 'package:bajet/core/theme/app_theme.dart';
import 'package:bajet/features/today/presentation/week_dial.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// A Wednesday, in a week of RM10 planned Monday to Thursday and the weekend off.
final _wednesday = DateTime.utc(2026, 10, 14);
const _plan = [1000, 1000, 1000, 1000, 0, 0, 0];
const _names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
final _week = [for (var i = 0; i < 7; i++) WeekDay(date: DateTime.utc(2026, 10, 12 + i), label: _names[i], spent: 0, planned: _plan[i])];

/// Pumps the dial with [spent] so far; [setSpent] changes it as a log would.
Future<void Function(int)> pumpDial(WidgetTester tester, int spent) async {
  late StateSetter set;
  var current = spent;
  await tester.pumpWidget(ProviderScope(
    overrides: [todayProvider.overrideWithValue(_wednesday)],
    child: MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: StatefulBuilder(builder: (context, setState) {
          set = setState;
          return WeekDial(days: _week, spent: current, cap: 4000);
        }),
      ),
    ),
  ));
  return (s) => set(() => current = s);
}

double arc(WidgetTester tester) {
  final paint = tester.widgetList<CustomPaint>(find.byType(CustomPaint)).firstWhere((p) => p.painter.runtimeType.toString() == '_DialPainter');
  return (paint.painter as dynamic).value as double;
}

void main() {
  testWidgets('it says what is left and what that leaves for each spending day still to come', (tester) async {
    await pumpDial(tester, 2350);
    await tester.pumpAndSettle();
    expect(find.text('RM16.50'), findsOneWidget);
    expect(find.text('left this week'), findsOneWidget);
    expect(find.text('Spent RM23.50 of RM40'), findsOneWidget);
    expect(find.text('RM8.25 a day for the 2 spending days left'), findsOneWidget);
  });

  testWidgets('past the plan for tonight it warns, and past the allowance it says how far over', (tester) async {
    final setSpent = await pumpDial(tester, 3350);
    await tester.pumpAndSettle();
    expect(find.text('Ahead of plan for today. RM3.25 a day for the 2 spending days left'), findsOneWidget);

    setSpent(4500);
    await tester.pumpAndSettle();
    expect(find.text('over this week'), findsOneWidget);
    expect(find.text('RM5.00 over this week'), findsOneWidget);
  });

  testWidgets('a log springs the arc past its new amount before it settles, while the figure never passes it', (tester) async {
    final setSpent = await pumpDial(tester, 2350);
    await tester.pumpAndSettle();
    expect(arc(tester), closeTo(2350 / 4000, 0.0001));

    setSpent(3550);
    var most = 0.0;
    final shown = <int>[];
    for (var i = 0; i < 70; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      most = arc(tester) > most ? arc(tester) : most;
      final text = tester.widgetList<Text>(find.textContaining(RegExp(r'^RM\d+\.\d\d$'))).first.data!;
      shown.add(int.parse(text.replaceAll(RegExp(r'[^0-9]'), '')));
    }
    await tester.pumpAndSettle();
    expect(most, greaterThan(3550 / 4000));
    expect(arc(tester), closeTo(3550 / 4000, 0.0001));
    // What is left only ever falls toward RM4.50, never below it.
    expect(shown.every((s) => s >= 450), isTrue);
    expect(shown.last, 450);
  });

  testWidgets('with animations off it moves straight to the new amount', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final setSpent = await pumpDial(tester, 2350);
    await tester.pump();
    expect(arc(tester), closeTo(2350 / 4000, 0.0001));
    setSpent(3550);
    await tester.pump();
    expect(arc(tester), closeTo(3550 / 4000, 0.0001));
  });
}
