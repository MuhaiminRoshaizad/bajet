/// One turn of the conversation with the coach.
class CoachMessage {
  const CoachMessage({required this.fromOwner, required this.text, this.looked = const []});

  final bool fromOwner;
  final String text;

  /// For a reply: what the coach looked up to give it, as the owner reads it.
  final List<String> looked;
}

enum CoachProblem { offline, badKey, busy, refused, other }

/// Why a question got no answer, worded for the owner.
class CoachException implements Exception {
  const CoachException(this.problem);

  final CoachProblem problem;

  String get message => switch (problem) {
        CoachProblem.offline => 'No connection. Your question is still here; send it again when you are online.',
        CoachProblem.badKey => 'Anthropic did not accept the key. Check it under Settings → Coach.',
        CoachProblem.busy => 'The coach is busy right now. Try again in a minute.',
        CoachProblem.refused => 'The coach cannot take that one. Ask about your money instead.',
        CoachProblem.other => 'The coach could not answer this time. Try again in a moment.',
      };
}

/// One request to Anthropic's Messages API, in its own JSON shapes: [messages]
/// are role and content maps, [tools] are tool definitions.
class CoachRequest {
  const CoachRequest({
    required this.model,
    required this.system,
    required this.messages,
    this.tools = const [],
    this.maxTokens = 4000,
    this.effort = 'low',
    this.noMoreTools = false,
    this.outputSchema,
    this.thinkingOff = false,
  });

  final String model;
  final String system;
  final List<Map<String, Object?>> messages;
  final List<Map<String, Object?>> tools;

  /// Room for the model's thinking and its reply together.
  final int maxTokens;
  final String effort;

  /// The tools stay declared but may no longer be called, so the model has
  /// to answer with what it has.
  final bool noMoreTools;

  /// A JSON schema the reply must match, for a classification.
  final Map<String, Object?>? outputSchema;
  final bool thinkingOff;
}

/// The model's answer: why it stopped and its content blocks, kept whole so
/// they can be sent back unchanged when a lookup follows.
class CoachTurn {
  const CoachTurn({required this.stopReason, required this.content});

  final String stopReason;
  final List<Map<String, Object?>> content;

  String get text => [for (final b in content) if (b['type'] == 'text') b['text'] as String].join('\n').trim();

  /// The lookups the model asked for: their id, name and input.
  List<(String, String, Map<String, Object?>)> get calls => [
        for (final b in content)
          if (b['type'] == 'tool_use') (b['id'] as String, b['name'] as String, (b['input'] as Map?)?.cast<String, Object?>() ?? const {}),
      ];
}

/// Sends a request to a language model. Behind this interface so the screen
/// can be tested without the network.
abstract interface class CoachClient {
  /// Throws [CoachException].
  Future<CoachTurn> send({required String apiKey, required CoachRequest request});
}

/// Where the owner's own API key and today's use of it are kept.
abstract interface class CoachKeyStore {
  Future<String?> readKey();
  Future<void> saveKey(String key);
  Future<void> deleteKey();

  /// Questions answered on [day].
  Future<int> usedOn(DateTime day);
  Future<void> recordUse(DateTime day);
}

/// Questions the coach answers per day, so a forgotten loop or a curious
/// afternoon cannot run up the owner's bill.
const coachDailyLimit = 10;
