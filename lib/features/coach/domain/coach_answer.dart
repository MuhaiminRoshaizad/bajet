import 'coach_client.dart';
import 'coach_lookups.dart';

/// The model the coach answers with: capable enough to reason about a
/// budget, and kinder to a personal key than the largest one.
const coachModel = 'claude-sonnet-5-5';

/// Lookups the coach may make for one question before it has to answer.
const coachMaxLookups = 4;

/// A reply and what was looked up to give it.
class CoachAnswer {
  const CoachAnswer(this.text, this.looked);

  final String text;
  final List<String> looked;
}

/// Answers the last question in [conversation], letting the model call the
/// lookups and running each one with [lookup]. Results go back inside
/// tool_result blocks, the place Anthropic keeps untrusted data, and after
/// [coachMaxLookups] rounds the model must answer with what it has.
Future<CoachAnswer> coachAnswer({
  required CoachClient client,
  required String apiKey,
  required String system,
  required List<CoachMessage> conversation,
  required LookupResult Function(String name, Map<String, Object?> input) lookup,
}) async {
  final messages = <Map<String, Object?>>[
    for (final m in conversation) {'role': m.fromUser ? 'user' : 'assistant', 'content': m.text},
  ];
  final looked = <String>[];
  for (var round = 0;; round++) {
    final turn = await client.send(
      apiKey: apiKey,
      request: CoachRequest(
        model: coachModel,
        system: system,
        messages: messages,
        tools: [for (final l in coachLookups) l.toJson()],
        noMoreTools: round >= coachMaxLookups,
      ),
    );
    final calls = turn.calls;
    if (calls.isEmpty) {
      if (turn.text.isEmpty) throw const CoachException(CoachProblem.other);
      return CoachAnswer(turn.text, looked);
    }
    // The assistant turn goes back exactly as it came, thinking included.
    messages.add({'role': 'assistant', 'content': turn.content});
    messages.add({
      'role': 'user',
      'content': [
        for (final (id, name, input) in calls)
          () {
            final r = lookup(name, input);
            if (!r.failed && !looked.contains(r.label)) looked.add(r.label);
            return {'type': 'tool_result', 'tool_use_id': id, 'content': r.text, if (r.failed) 'is_error': true};
          }(),
      ],
    });
  }
}
