/// One turn of the conversation with the coach.
class CoachMessage {
  const CoachMessage({required this.fromOwner, required this.text});

  final bool fromOwner;
  final String text;
}

enum CoachProblem { offline, badKey, busy, other }

/// Why a question got no answer, worded for the owner.
class CoachException implements Exception {
  const CoachException(this.problem);

  final CoachProblem problem;

  String get message => switch (problem) {
        CoachProblem.offline => 'No connection. Your question is still here; send it again when you are online.',
        CoachProblem.badKey => 'Anthropic did not accept the key. Check it under Settings → Coach.',
        CoachProblem.busy => 'The coach is busy right now. Try again in a minute.',
        CoachProblem.other => 'The coach could not answer this time. Try again in a moment.',
      };
}

/// Asks a language model for the coach's reply. Behind this interface so the
/// screen can be tested without the network.
abstract interface class CoachClient {
  /// Returns the reply to the last message in [conversation]. Throws
  /// [CoachException].
  Future<String> ask({required String apiKey, required String system, required List<CoachMessage> conversation});
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
