import 'package:bajet/features/plan/domain/plan_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/fake_repositories.dart';

Future<void> openRhythm(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Settings'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Weekly rhythm'));
  await tester.pumpAndSettle();
}

Future<void> openDay(WidgetTester tester, String day) async {
  await tester.tap(find.text(day));
  await tester.pumpAndSettle();
}

Future<void> save(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(FilledButton, 'Save'));
  await tester.pumpAndSettle();
}

/// RM50 a week spread evenly, as setup leaves it.
void spreadWeek(FakeWorld w) {
  final daily = spreadOverWeek(5000);
  for (var d = 1; d <= 7; d++) {
    w.saveRule(WeeklyRule(weekday: d, label: d <= 5 ? 'Weekday' : 'Weekend', type: DayType.spend, plannedSpend: daily[d - 1]));
  }
}

Future<List<int>> planned(FakeWorld world) async => [for (final r in await world.watchRules().first) r.plannedSpend];

void main() {
  testWidgets('lists all seven days with what they cost', (tester) async {
    await pumpApp(tester);
    await openRhythm(tester);
    for (final day in ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']) {
      expect(find.text(day), findsOneWidget);
    }
    expect(find.textContaining('Planned in total: RM0.00 a week.'), findsOneWidget);
  });

  testWidgets('editing a day saves its name, type and amount', (tester) async {
    await pumpApp(tester);
    await openRhythm(tester);
    await openDay(tester, 'Monday');

    await tester.enterText(find.widgetWithText(TextFormField, 'Name'), 'Office day');
    await tester.tap(find.text('Flexible'));
    await tester.enterText(find.widgetWithText(TextFormField, 'Planned spend'), '1200');
    await save(tester);

    expect(find.textContaining('Planned in total: RM12.00 a week.'), findsOneWidget);
    expect(find.text('Office day · Flexible'), findsOneWidget);
  });

  testWidgets('a no-spending day hands its plan to the other days, so the week keeps its total', (tester) async {
    final world = await pumpApp(tester, seed: spreadWeek);
    await openRhythm(tester);
    await openDay(tester, 'Saturday');

    await tester.tap(find.text('No spending'));
    await tester.pump();
    expect(find.text('Its RM7.14 moves to the other 6 spending days, so the week still plans RM50.00.'), findsOneWidget);
    await save(tester);

    expect(await planned(world), [834, 834, 833, 833, 833, 0, 833]);
    expect(find.textContaining('Planned in total: RM50.00 a week.'), findsOneWidget);
  });

  testWidgets('a fasting day becomes a no-spending day at RM0', (tester) async {
    final world = await pumpApp(tester, seed: spreadWeek);
    await openRhythm(tester);
    await openDay(tester, 'Monday');

    await tester.tap(find.text('Fasting day'));
    await tester.pump();
    final amount = tester.widget<TextField>(find.descendant(of: find.widgetWithText(TextFormField, 'Planned spend'), matching: find.byType(TextField)));
    expect((amount.enabled, amount.controller!.text), (false, ''));
    await save(tester);

    final monday = (await world.watchRules().first).first;
    expect((monday.type, monday.plannedSpend, monday.isFastingDay), (DayType.zero, 0, true));
    expect(find.text('Fasting'), findsOneWidget);
    expect(find.text('RM0.00'), findsNothing);
  });

  testWidgets('an allowance the days do not add up to can be spread over them again', (tester) async {
    final world = await pumpApp(tester);
    await openRhythm(tester);

    expect(find.text('RM50.00 of your RM50.00 weekly allowance is not planned on any day.'), findsOneWidget);
    await tester.tap(find.text('Spread RM50.00 over the 7 spending days'));
    await tester.pumpAndSettle();

    expect(await planned(world), spreadOverWeek(5000));
    expect(find.textContaining('weekly allowance is not planned'), findsNothing);
  });
}
