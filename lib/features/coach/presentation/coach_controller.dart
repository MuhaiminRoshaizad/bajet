import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../domain/coach_answer.dart';
import '../domain/coach_client.dart';
import '../domain/coach_lookups.dart';
import '../domain/coach_prompt.dart';
import 'coach_providers.dart';

class CoachChat {
  const CoachChat({this.messages = const [], this.sending = false, this.error});

  final List<CoachMessage> messages;
  final bool sending;

  /// Why the last question got no answer, worded for the user.
  final String? error;

  /// The last question is waiting for an answer that failed.
  bool get canRetry => error != null && messages.isNotEmpty && messages.last.fromUser;
}

/// The conversation on the Coach tab. Held in memory only: it is gone when
/// the app closes, and nothing of it is stored.
class CoachController extends Notifier<CoachChat> {
  @override
  CoachChat build() => const CoachChat();

  Future<void> ask(String question) async {
    final text = question.trim();
    if (text.isEmpty || state.sending) return;
    state = CoachChat(messages: [...state.messages, CoachMessage(fromUser: true, text: text)]);
    await _answer();
  }

  /// Sends the unanswered last question again.
  Future<void> retry() async {
    if (state.canRetry && !state.sending) await _answer();
  }

  Future<void> _answer() async {
    final store = ref.read(coachKeyStoreProvider);
    final today = ref.read(todayProvider);
    final key = await ref.read(coachKeyProvider.future);
    final data = ref.read(coachDataProvider);
    if (key == null) return _fail('Add your Anthropic key under Settings → Coach first.');
    if (data == null) return _fail('Your figures are still loading. Try again in a moment.');
    if (await store.usedOn(today) >= coachDailyLimit) {
      return _fail("That's today's $coachDailyLimit questions. The coach is back tomorrow.");
    }
    state = CoachChat(messages: state.messages, sending: true);
    try {
      final answer = await coachAnswer(
        client: ref.read(coachClientProvider),
        apiKey: key,
        system: coachSystemPrompt(today),
        conversation: state.messages,
        lookup: (name, input) => runLookup(name, input, data),
      );
      await store.recordUse(today);
      ref.invalidate(coachUsedTodayProvider);
      state = CoachChat(messages: [...state.messages, CoachMessage(fromUser: false, text: answer.text, looked: answer.looked)]);
    } on CoachException catch (e) {
      _fail(e.message);
    }
  }

  void _fail(String message) => state = CoachChat(messages: state.messages, error: message);
}

final coachControllerProvider = NotifierProvider<CoachController, CoachChat>(CoachController.new);
