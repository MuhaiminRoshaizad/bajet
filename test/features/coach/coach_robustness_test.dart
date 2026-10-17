import 'package:bajet/features/coach/presentation/coach_controller.dart';
import 'package:bajet/features/coach/presentation/coach_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/app_harness.dart';
import 'coach_screen_test.dart' show ask, openCoach;

CoachController coachOf(WidgetTester tester) => ProviderScope.containerOf(tester.element(find.byType(CoachScreen))).read(coachControllerProvider.notifier);

void main() {
  testWidgets('a question sent twice in a rush reaches the coach once', (tester) async {
    final world = await openCoach(tester);
    final coach = coachOf(tester);
    coach.ask('How did this week go?');
    coach.ask('How did this week go?');
    await tester.pumpAndSettle();
    expect(world.coach.requests, hasLength(1));
    expect(find.text('How did this week go?'), findsOneWidget);
  });

  testWidgets('a card tapped twice in a rush logs once', (tester) async {
    final world = await openCoach(tester);
    world.coach.lookups.add(('bajet_propose_log', {'kind': 'spending', 'amount_rm': 12, 'category': 'Food', 'label': 'Lunch'}));
    await ask(tester, 'Log RM12 lunch');
    final coach = coachOf(tester);
    final at = coach.state.messages.length - 1;
    coach.confirm(at, 0);
    coach.confirm(at, 0);
    await tester.pumpAndSettle();
    expect(world.entries.where((e) => e.label == 'Lunch'), hasLength(1));
  });

  testWidgets('a bill already paid from the Plan tab is not paid again from an old card', (tester) async {
    late int rent;
    final world = await openCoach(tester, seed: (w) async {
      rent = await w.addRecurring(name: 'Rent', isIncome: false, amount: 50000, categoryKey: 'bills', nextDue: DateTime.utc(testToday.year, testToday.month, testToday.day + 3));
    });
    world.coach.lookups.add(('bajet_propose_bill_paid', {'bill': 'Rent'}));
    await ask(tester, 'I paid the rent');
    expect(find.text('Mark this bill paid?'), findsOneWidget);

    await world.confirmRecurring(rent, paidOn: testToday);
    await tester.pumpAndSettle();
    final due = world.recurring.single.nextDue;
    await tester.tap(find.widgetWithText(FilledButton, 'Mark paid'));
    await tester.pumpAndSettle();
    expect(world.entries.where((e) => e.label == 'Rent'), hasLength(1), reason: 'paid once, from the Plan tab');
    expect(world.recurring.single.nextDue, due);
    expect(find.text('Already changed elsewhere, nothing done'), findsOneWidget);
  });
}
