import 'package:bajet/features/coach/domain/coach_answer.dart';
import 'package:bajet/features/coach/domain/coach_client.dart';
import 'package:bajet/features/coach/domain/coach_lookups.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_repositories.dart';

const _question = [CoachMessage(fromOwner: true, text: 'Where is my money?')];

Future<CoachAnswer> answer(FakeCoach coach, {LookupResult Function(String, Map<String, Object?>)? lookup}) => coachAnswer(
      client: coach,
      apiKey: 'test-key',
      system: 'Be brief.',
      conversation: _question,
      lookup: lookup ?? (name, _) => LookupResult('figures from $name', name == 'bajet_accounts' ? 'Accounts' : name),
    );

void main() {
  test('a lookup runs on the phone and its result goes back as a tool result, then the reply comes', () async {
    final coach = FakeCoach()..lookups.add(('bajet_accounts', const {}));
    final a = await answer(coach);
    expect(a.text, 'You are on track.');
    expect(a.looked, ['Accounts']);
    expect(coach.requests, hasLength(2));
    final second = coach.requests.last.messages;
    expect(second[1]['role'], 'assistant');
    expect(second[2], {
      'role': 'user',
      'content': [
        {'type': 'tool_result', 'tool_use_id': 'toolu_1', 'content': 'figures from bajet_accounts'},
      ],
    });
    expect(coach.requests.first.model, coachModel);
  });

  test('a lookup that cannot be used is marked as an error and not shown as looked at', () async {
    final coach = FakeCoach()..lookups.add(('write_python', const {}));
    final a = await answer(coach, lookup: (name, _) => LookupResult('There is no lookup called $name.', name, failed: true));
    expect(a.looked, isEmpty);
    expect(coach.lookedUp, contains('There is no lookup called write_python.'));
    final result = (coach.requests.last.messages[2]['content'] as List).single as Map;
    expect(result['is_error'], isTrue);
  });

  test('after four rounds of lookups the model has to answer with what it has', () async {
    final coach = FakeCoach();
    for (var i = 0; i < 6; i++) {
      coach.lookups.add(('bajet_overview', const {}));
    }
    final a = await answer(coach);
    // The fake keeps asking, so the fifth request already forbids lookups.
    expect([for (final r in coach.requests.take(5)) r.noMoreTools], [false, false, false, false, true]);
    expect(a.text, isNotEmpty);
  });

  test('a reply with no words is a problem, not an empty bubble', () async {
    final coach = FakeCoach()..reply = '   ';
    expect(() => answer(coach), throwsA(isA<CoachException>().having((e) => e.problem, 'problem', CoachProblem.other)));
  });
}
