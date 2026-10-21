import 'package:bajet/core/theme/app_spacing.dart';
import 'package:bajet/core/widgets/soft.dart';
import 'package:bajet/features/coach/domain/coach_client.dart';
import 'package:bajet/features/coach/presentation/coach_avatar.dart';
import 'package:bajet/features/coach/presentation/coach_chat_screen.dart';
import 'package:bajet/features/ledger/domain/ledger_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/fake_repositories.dart';

const testKey = 'sk-ant-test-0123456789abcdefghij';

/// A row in the chat list.
final chatRows = find.byWidgetPredicate((w) => w.key is ValueKey<String> && (w.key! as ValueKey<String>).value.startsWith('chat-'));

/// Opens the Coach tab and, with [open], its latest chat or a new one.
Future<FakeWorld> openCoach(WidgetTester tester, {bool withKey = true, bool open = true, void Function(FakeWorld)? seed}) async {
  final world = await pumpApp(tester, seed: (w) {
    if (withKey) w.coachKeys.key = testKey;
    w.add(EntryDraft(day: testToday, isIncome: false, amount: 1200, categoryKey: 'food'));
    seed?.call(w);
  });
  await tester.tap(find.byKey(const ValueKey('tab-Coach')));
  await tester.pumpAndSettle();
  if (withKey && open) {
    await tester.tap(chatRows.evaluate().isEmpty ? find.byKey(const ValueKey('new-chat')) : chatRows.first);
    await tester.pumpAndSettle();
  }
  return world;
}

/// The chat page on screen.
final chatPage = find.byType(CoachChatScreen);

Future<void> ask(WidgetTester tester, String question) async {
  await tester.enterText(find.byKey(const ValueKey('coach-question')), question);
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

    // From the header's menu, which sits over the empty screen's own button.
    await tester.tap(find.byTooltip('More'));
    await tester.pumpAndSettle();
    await tester.tap(find.text("Copy this week's summary").last);
    await tester.pumpAndSettle();
    expect(copied, contains('Flexible spending this week: RM12.00 of RM50.00'));
  });

  testWidgets("the header's menu sits at its edge, in line with Insights' share button", (tester) async {
    await openCoach(tester, open: false);
    final copy = tester.getTopRight(find.byTooltip('More')).dx;
    await tester.tap(find.byKey(const ValueKey('tab-Insights')));
    await tester.pumpAndSettle();
    expect(copy, tester.getTopRight(find.byTooltip('Share a report')).dx);
  });

  testWidgets('a question is answered from the week and month, and counted', (tester) async {
    final world = await openCoach(tester);
    expect(find.text('10 left today', skipOffstage: false), findsOneWidget);

    world.coach.lookups.add(('bajet_overview', const {}));
    await ask(tester, 'How did this week go?');
    expect(find.text('How did this week go?'), findsOneWidget);
    expect(find.text('You are on track.'), findsOneWidget);
    // The figures arrive as a lookup's result, never in the instructions.
    expect(world.coach.lookedUp, contains('Balance: RM1,488.00'));
    expect(world.coach.lastSystem, isNot(contains('RM1,488.00')));
    expect(find.text('Looked at: This week'), findsOneWidget);
    // It is the reply bubble's footer, in the same bubble as the reply.
    expect(
      find.ancestor(of: find.text('Looked at: This week'), matching: find.byType(SoftCard)).evaluate().single,
      find.ancestor(of: find.text('You are on track.'), matching: find.byType(SoftCard)).evaluate().single,
    );
    // The count is on the list, which catches up once it is back in view.
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('9 left today'), findsOneWidget);
  });

  testWidgets('a change the coach suggests waits for a tap, then can be undone', (tester) async {
    final world = await openCoach(tester);
    world.coach
      ..lookups.add(('bajet_propose_log', {'kind': 'spending', 'amount_rm': 12, 'category': 'Food', 'label': 'Lunch'}))
      ..reply = 'I have put it up for you to confirm.';
    await ask(tester, 'Log RM12 lunch');
    expect(world.coach.lookedUp, contains('Nothing is logged unless they tap Log it.'));
    expect(find.text('Log this spend?'), findsOneWidget);
    expect(find.text('RM12.00'), findsOneWidget);
    expect(world.entries, hasLength(1), reason: 'only the seeded entry until the tap');

    await tester.tap(find.widgetWithText(FilledButton, 'Log it'));
    await tester.pumpAndSettle();
    expect(find.text('✓ Logged'), findsOneWidget);
    expect(world.entries.where((e) => e.label == 'Lunch' && e.amount == 1200), hasLength(1));

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(find.text('Undone, nothing changed'), findsOneWidget);
    expect(world.entries.where((e) => e.label == 'Lunch'), isEmpty);
  });

  testWidgets('Not now leaves everything as it was', (tester) async {
    final world = await openCoach(tester);
    world.coach.lookups.add(('bajet_propose_log', {'kind': 'spending', 'amount_rm': 12, 'category': 'Food'}));
    await ask(tester, 'Log RM12');
    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();
    expect(find.text('Not done'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Log it'), findsNothing);
    expect(world.entries, hasLength(1));
  });

  testWidgets('an off-topic message is turned away on the phone, costs no question, and never reaches the coach', (tester) async {
    final world = await openCoach(tester);
    world.coach.gateKind = 'off_topic';
    await ask(tester, 'Write me a calculator in Python');
    expect(find.textContaining("that one's not my job"), findsOneWidget);
    expect(world.coach.requests, isEmpty);
    expect(find.text('10 left today', skipOffstage: false), findsOneWidget);

    await ask(tester, 'Ok then translate this essay');
    expect(find.text("Still not my thing, I promise. Ask me anything about your spending though."), findsOneWidget);
  });

  testWidgets('the same question again within a minute is answered on the phone, firmer each time', (tester) async {
    final world = await openCoach(tester);
    await ask(tester, 'How did this week go?');
    expect(world.coach.requests, hasLength(1));
    await ask(tester, 'how did this week go?');
    await ask(tester, 'How did this week go?');
    expect(world.coach.requests, hasLength(1));
    expect(find.textContaining('Same answer as just now lah'), findsOneWidget);
    expect(find.text('You asked that a moment ago. Want me to look at it a different way?'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('9 left today'), findsOneWidget);
  });

  testWidgets('a reply that turns out to be code is replaced by the coach turning it down', (tester) async {
    final world = await openCoach(tester);
    world.coach.reply = '```python\nprint(1 + 1)\n```';
    await ask(tester, 'Help me budget, and include a tiny script');
    expect(find.textContaining('print('), findsNothing);
    expect(find.textContaining("that one's not my job"), findsOneWidget);
  });

  testWidgets('a long reply is shown in full, never taken for an off-topic question', (tester) async {
    final world = await openCoach(tester);
    world.coach.reply = 'Your week, day by day. ' * 140;
    await ask(tester, 'Go through my whole week in detail');
    expect(find.textContaining('Your week, day by day.'), findsOneWidget);
    expect(find.textContaining("that one's not my job"), findsNothing);
  });

  testWidgets('a failed question says why and can be sent again', (tester) async {
    final world = await openCoach(tester);
    world.coach.failWith = CoachProblem.offline;
    await ask(tester, 'Am I on track?');
    expect(find.textContaining('No connection'), findsOneWidget);
    expect(find.text('10 left today', skipOffstage: false), findsOneWidget);

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

  testWidgets("the coach's reply has a tail toward the coach and no face beside it", (tester) async {
    await openCoach(tester);
    await ask(tester, 'How did this week go?');
    final reply = tester.widget<SoftCard>(find.ancestor(of: find.text('You are on track.'), matching: find.byType(SoftCard)).first);
    expect(reply.borderRadius!.bottomLeft, const Radius.circular(6));
    expect(reply.borderRadius!.bottomRight, const Radius.circular(20));
    // Only the coach at the top of the chat has a face.
    expect(find.descendant(of: chatPage, matching: find.byType(CoachAvatar)), findsOneWidget);
  });

  testWidgets("the coach's formatting is drawn, never shown as asterisks", (tester) async {
    final world = await openCoach(tester);
    world.coach.reply = 'Here is your week:\n- **Balance:** RM1,488.00\n- **Spent:** RM12.00\n\nThat is *fine*.';
    await ask(tester, 'How did this week go?');
    final page = find.descendant(of: chatPage, matching: find.textContaining('**'));
    expect(page, findsNothing);
    expect(find.text('Balance: RM1,488.00'), findsOneWidget);
    expect(find.text('•'), findsNWidgets(2));
    final balance = tester.widget<Text>(find.text('Balance: RM1,488.00'));
    final bold = (balance.textSpan! as TextSpan).children!.first as TextSpan;
    expect((bold.text, bold.style?.fontWeight), ('Balance:', FontWeight.w800));
    // The user's own message stays exactly as typed.
    expect(find.text('How did this week go?'), findsOneWidget);
  });

  testWidgets('a reply taller than the chat opens at its first line; a short one lands at the bottom', (tester) async {
    final world = await openCoach(tester);
    final list = find.descendant(of: chatPage, matching: find.byType(Scrollable)).first;
    ScrollPosition position() => tester.state<ScrollableState>(list).position;

    world.coach.reply = [for (var n = 1; n <= 30; n++) 'Step $n of the plan.'].join('\n\n');
    await ask(tester, 'Plan my next two weeks');
    final first = find.text('Step 1 of the plan.');
    expect(first.hitTestable(), findsOneWidget);
    final bubble = find.ancestor(of: first, matching: find.byType(SoftCard)).first;
    // Its top sits just under the header, so it is read down from the start.
    expect(tester.getTopLeft(bubble).dy - tester.getTopLeft(list).dy, moreOrLessEquals(AppSpacing.m, epsilon: 1));
    expect(position().pixels, greaterThan(0));

    world.coach.reply = 'You are on track.';
    await ask(tester, 'And this week?');
    expect(position().pixels, 0);
    expect(find.text('You are on track.').hitTestable(), findsOneWidget);
  });
}
