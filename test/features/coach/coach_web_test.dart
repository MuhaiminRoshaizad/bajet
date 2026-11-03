import 'package:bajet/features/coach/data/drift_coach_chat_repository.dart';
import 'package:bajet/features/coach/domain/coach_answer.dart';
import 'package:bajet/features/coach/domain/coach_client.dart';
import 'package:bajet/features/coach/domain/coach_lookups.dart';
import 'package:bajet/features/coach/domain/coach_prompt.dart';
import 'package:bajet/features/coach/domain/coach_settings.dart';
import 'package:bajet/core/database/app_database.dart' as db;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_repositories.dart';
import 'coach_screen_test.dart' show ask, openCoach;
import 'coach_switch_test.dart' show openChatSettings;

Future<CoachAnswer> answer(FakeCoach coach, {bool web = false}) => coachAnswer(
      client: coach,
      apiKey: 'test-key',
      system: 'Be brief.',
      conversation: const [CoachMessage(fromUser: true, text: 'any vet near Petaling Jaya and how much')],
      tools: coachLookups,
      lookup: (name, _) => LookupResult('', name),
      web: web,
    );

List<String?> toolNames(CoachRequest r) => [for (final t in r.tools) t['name'] as String?];

void main() {
  test('only a chat that allows the web is given search and page reading, searched from Malaysia', () async {
    final off = FakeCoach();
    await answer(off);
    expect(toolNames(off.requests.single), isNot(contains('web_search')));

    final on = FakeCoach();
    await answer(on, web: true);
    final tools = on.requests.single.tools;
    final search = tools.firstWhere((t) => t['name'] == 'web_search');
    expect(search['type'], 'web_search_20260209');
    expect((search['user_location'] as Map)['country'], 'MY');
    expect(toolNames(on.requests.single), contains('web_fetch'));
  });

  test('a paused search is sent back as it is and carries on, and the reply says what was searched', () async {
    final coach = FakeCoach()
      ..turns.add(const CoachTurn(stopReason: 'pause_turn', content: [
        {'type': 'server_tool_use', 'id': 'srvtoolu_1', 'name': 'web_search', 'input': {'query': 'vet Petaling Jaya check-up price'}},
        {'type': 'web_search_tool_result', 'tool_use_id': 'srvtoolu_1', 'content': []},
      ]))
      ..turns.add(const CoachTurn(stopReason: 'end_turn', content: [
        {'type': 'server_tool_use', 'id': 'srvtoolu_2', 'name': 'web_fetch', 'input': {'url': 'https://example.com/fees'}},
        {'type': 'web_fetch_tool_result', 'tool_use_id': 'srvtoolu_2', 'content': {}},
        {'type': 'text', 'text': 'Clinic one lists a check-up at RM50.00.'},
      ]));
    final a = await answer(coach, web: true);
    expect(a.text, 'Clinic one lists a check-up at RM50.00.');
    expect(a.looked, ['Web: 1 search', '1 web page']);
    expect(coach.requests, hasLength(2));
    final resent = coach.requests.last.messages.last;
    expect((resent['role'], (resent['content'] as List).first['type']), ('assistant', 'server_tool_use'));
  });

  test('the coach is told what the web is for and that nothing of the user goes into a search', () {
    final on = coachSystemPrompt(DateTime(2026, 11, 3), CoachPersonality.friendly, web: true);
    expect(on, contains('Never put their figures, their name or anything from their entries into a search'));
    expect(on, contains('when a page shows no price, say so rather than guess'));
    final off = coachSystemPrompt(DateTime(2026, 11, 3), CoachPersonality.friendly);
    expect(off, contains("web search can be turned on in this chat's settings"));
    expect(off, isNot(contains('you may search the web')));
  });

  test('a chat remembers whether it may search the web', () async {
    final database = db.AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repo = DriftCoachChatRepository(database);
    final at = DateTime(2026, 11, 3, 9);
    final id = await repo.createThread(chatWith([CoachMessage(fromUser: true, text: 'Hi', sentAt: at)]));
    expect((await repo.load()).single.webSearch, isFalse);
    await repo.saveThread((await repo.load()).single.copyWith(webSearch: true));
    expect((await repo.load()).firstWhere((t) => t.id == id).webSearch, isTrue);
  });

  testWidgets("web search is off in a new chat, and turning it on in the chat's settings gives the coach the web", (tester) async {
    final world = await openCoach(tester);
    await ask(tester, 'any vet near Petaling Jaya?');
    expect(toolNames(world.coach.requests.last), isNot(contains('web_search')));

    await openChatSettings(tester);
    final toggle = find.byKey(const ValueKey('web-search'));
    await tester.ensureVisible(toggle);
    await tester.pumpAndSettle();
    expect(tester.widget<SwitchListTile>(toggle).value, isFalse);
    await tester.tap(toggle);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Web search on for this chat'), findsOneWidget);
    expect((await world.coachChat.load()).single.webSearch, isTrue);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await ask(tester, 'and how much is a check-up?');
    expect(toolNames(world.coach.requests.last), contains('web_search'));
  });
}
