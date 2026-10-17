import 'package:bajet/features/coach/domain/coach_client.dart';
import 'package:bajet/features/ledger/domain/ledger_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/fake_repositories.dart';

const testKey = 'sk-ant-test-0123456789abcdefghij';

Future<FakeWorld> openCoach(WidgetTester tester, {bool withKey = true}) async {
  final world = await pumpApp(tester, seed: (w) {
    if (withKey) w.coachKeys.key = testKey;
    w.add(EntryDraft(day: testToday, isIncome: false, amount: 1200, categoryKey: 'food'));
  });
  await tester.tap(find.byKey(const ValueKey('tab-Coach')));
  await tester.pumpAndSettle();
  return world;
}

Future<void> ask(WidgetTester tester, String question) async {
  await tester.enterText(find.byType(TextField), question);
  await tester.tap(find.byTooltip('Send'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('without a key it explains, links to Settings, and still copies the summary', (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') copied = (call.arguments as Map)['text'] as String;
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));

    await openCoach(tester, withKey: false);
    expect(find.widgetWithText(FilledButton, 'Add your key'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);

    await tester.tap(find.byTooltip("Copy this week's summary"));
    await tester.pumpAndSettle();
    expect(copied, contains('Flexible spending this week: RM12.00 of RM50.00'));
  });

  testWidgets("the copy button sits at the header's edge, in line with Insights' share button", (tester) async {
    await openCoach(tester);
    final copy = tester.getTopRight(find.byTooltip("Copy this week's summary")).dx;
    await tester.tap(find.byKey(const ValueKey('tab-Insights')));
    await tester.pumpAndSettle();
    expect(copy, tester.getTopRight(find.byTooltip('Share a report')).dx);
  });

  testWidgets('a question is answered from the week and month, and counted', (tester) async {
    final world = await openCoach(tester);
    expect(find.text('10 left today'), findsOneWidget);

    world.coach.lookups.add(('bajet_overview', const {}));
    await ask(tester, 'How did this week go?');
    expect(find.text('How did this week go?'), findsOneWidget);
    expect(find.text('You are on track.'), findsOneWidget);
    // The figures arrive as a lookup's result, never in the instructions.
    expect(world.coach.lookedUp, contains('Balance: RM1,488.00'));
    expect(world.coach.lastSystem, isNot(contains('RM1,488.00')));
    expect(find.text('Looked at: This week'), findsOneWidget);
    expect(find.text('9 left today'), findsOneWidget);
  });

  testWidgets('a failed question says why and can be sent again', (tester) async {
    final world = await openCoach(tester);
    world.coach.failWith = CoachProblem.offline;
    await ask(tester, 'Am I on track?');
    expect(find.textContaining('No connection'), findsOneWidget);
    expect(find.text('10 left today'), findsOneWidget);

    world.coach.failWith = null;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('You are on track.'), findsOneWidget);
  });

  testWidgets('after ten questions in a day the coach stops answering', (tester) async {
    final world = await openCoach(tester);
    world.coachKeys.used[testToday] = coachDailyLimit;
    await ask(tester, 'One more?');
    expect(find.textContaining("That's today's 10 questions"), findsOneWidget);
    expect(world.coach.requests, isEmpty);
  });
}
