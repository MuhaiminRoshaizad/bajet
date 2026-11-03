import 'coach_client.dart';
import 'coach_lookups.dart';

/// The model the coach answers with: capable enough to reason about a
/// budget, and kinder to a personal key than the largest one.
const coachModel = 'claude-sonnet-5-5';

/// Lookups the coach may make for one question before it has to answer:
/// enough to read entries, the plan and a what-if before a money question.
const coachMaxLookups = 8;

/// How hard the coach thinks. Low answered from the first figure it saw and
/// once took an unpaid bill for paid; medium checks its figures first.
const coachEffort = 'medium';

/// Room for the coach's thinking and its reply together at [coachEffort].
const coachMaxTokens = 8000;

/// Anthropic's own web search and page reading, for a chat that allows
/// them: a few searches and pages a question, searched from Malaysia.
const webTools = <Map<String, Object?>>[
  {
    'type': 'web_search_20260209',
    'name': 'web_search',
    'max_uses': 3,
    'user_location': {'type': 'approximate', 'country': 'MY', 'timezone': 'Asia/Kuala_Lumpur'},
  },
  {'type': 'web_fetch_20260209', 'name': 'web_fetch', 'max_uses': 2},
];

/// What the web lookups in [content] were, as the user reads them.
List<String> webLooked(List<Map<String, Object?>> content) {
  int count(String name) => content.where((b) => b['type'] == 'server_tool_use' && b['name'] == name).length;
  final searches = count('web_search'), pages = count('web_fetch');
  return [
    if (searches > 0) 'Web: $searches ${searches == 1 ? 'search' : 'searches'}',
    if (pages > 0) '$pages web ${pages == 1 ? 'page' : 'pages'}',
  ];
}

/// A reply and what was looked up to give it.
class CoachAnswer {
  const CoachAnswer(this.text, this.looked);

  final String text;
  final List<String> looked;
}

/// What the coach is sent for [m]: a reply carries the words it answers
/// ahead of the question, so "this one" can be understood.
String asked(CoachMessage m) => m.quote == null ? m.text : 'Replying to your words: "${m.quote}"\n\n${m.text}';

/// Answers the last question in [conversation], letting the model call
/// [tools] and running each call with [lookup]. Results go back inside
/// tool_result blocks, the place Anthropic keeps untrusted data, and after
/// [coachMaxLookups] rounds the model must answer with what it has.
Future<CoachAnswer> coachAnswer({
  required CoachClient client,
  required String apiKey,
  required String system,
  required List<CoachMessage> conversation,
  required List<CoachLookup> tools,
  required LookupResult Function(String name, Map<String, Object?> input) lookup,
  bool web = false,
}) async {
  final messages = <Map<String, Object?>>[
    for (final m in conversation) {'role': m.fromUser ? 'user' : 'assistant', 'content': asked(m)},
  ];
  final looked = <String>[];
  for (var round = 0;; round++) {
    final turn = await client.send(
      apiKey: apiKey,
      request: CoachRequest(
        model: coachModel,
        effort: coachEffort,
        maxTokens: coachMaxTokens,
        system: system,
        messages: messages,
        tools: [for (final l in tools) l.toJson(), if (web) ...webTools],
        noMoreTools: round >= coachMaxLookups,
      ),
    );
    final calls = turn.calls;
    // A long search pauses the turn; sent back as it is, it carries on.
    if (turn.stopReason == 'pause_turn') {
      messages.add({'role': 'assistant', 'content': turn.content});
      continue;
    }
    final searched = webLooked([for (final m in messages) if (m['role'] == 'assistant' && m['content'] is List) ...(m['content'] as List).cast(), ...turn.content]);
    if (calls.isEmpty) {
      if (turn.text.isEmpty) throw const CoachException(CoachProblem.other);
      return CoachAnswer(turn.text, [...searched, ...looked]);
    }
    // The assistant turn goes back exactly as it came, thinking included.
    messages.add({'role': 'assistant', 'content': turn.content});
    messages.add({
      'role': 'user',
      'content': [
        for (final (id, name, input) in calls)
          () {
            final r = lookup(name, input);
            if (!r.failed && !r.label.startsWith('A suggestion') && !looked.contains(r.label)) looked.add(r.label);
            return {'type': 'tool_result', 'tool_use_id': id, 'content': r.text, if (r.failed) 'is_error': true};
          }(),
      ],
    });
  }
}
