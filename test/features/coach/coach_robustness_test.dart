import 'package:bajet/features/coach/presentation/coach_controller.dart';
import 'package:bajet/features/coach/presentation/coach_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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
}
