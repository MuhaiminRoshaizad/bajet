import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../accounts/presentation/account_providers.dart';
import '../../ledger/presentation/ledger_providers.dart';
import '../../plan/presentation/plan_providers.dart';
import '../domain/coach_answer.dart';
import '../domain/coach_client.dart';
import '../domain/coach_lookups.dart';
import '../domain/coach_prompt.dart';
import '../domain/coach_proposals.dart';
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
      final cards = <CoachCard>[];
      final answer = await coachAnswer(
        client: ref.read(coachClientProvider),
        apiKey: key,
        system: coachSystemPrompt(today),
        conversation: state.messages,
        tools: [...coachLookups, ...proposalTools],
        lookup: (name, input) {
          if (!name.startsWith('bajet_propose_')) return runLookup(name, input, data);
          final (result, proposal) = propose(name, input, data);
          if (proposal != null) cards.add(CoachCard(proposal));
          return result;
        },
      );
      await store.recordUse(today);
      ref.invalidate(coachUsedTodayProvider);
      state = CoachChat(messages: [...state.messages, CoachMessage(fromUser: false, text: answer.text, looked: answer.looked, cards: cards)]);
    } on CoachException catch (e) {
      _fail(e.message);
    }
  }

  /// Does what card [card] of message [message] suggested.
  Future<void> confirm(int message, int card) async {
    final c = state.messages[message].cards[card];
    if (c.state != CardState.waiting) return;
    final undoId = switch (c.proposal) {
      LogProposal(:final draft) => await ref.read(ledgerRepositoryProvider).add(draft),
      MoveProposal(:final fromId, :final toId, :final amount, :final day, :final note) =>
        await ref.read(accountRepositoryProvider).transfer(fromId: fromId, toId: toId, amount: amount, day: day, note: note),
      BillPaidProposal(:final item) => await ref.read(planRepositoryProvider).confirmRecurring(item.id, paidOn: ref.read(todayProvider)).then((_) => null),
    };
    _setCard(message, card, c.copyWith(state: CardState.done, undoId: undoId));
  }

  void decline(int message, int card) {
    final c = state.messages[message].cards[card];
    if (c.state == CardState.waiting) _setCard(message, card, c.copyWith(state: CardState.declined));
  }

  /// Takes back what a confirmed card did.
  Future<void> undo(int message, int card) async {
    final c = state.messages[message].cards[card];
    if (!c.canUndo) return;
    switch (c.proposal) {
      case LogProposal():
        await ref.read(ledgerRepositoryProvider).delete(c.undoId!);
      case MoveProposal():
        await ref.read(accountRepositoryProvider).deleteTransfer(c.undoId!);
      case BillPaidProposal():
        return;
    }
    _setCard(message, card, c.copyWith(state: CardState.undone));
  }

  void _setCard(int message, int card, CoachCard updated) {
    final messages = [...state.messages];
    final cards = [...messages[message].cards]..[card] = updated;
    messages[message] = messages[message].withCards(cards);
    state = CoachChat(messages: messages, sending: state.sending, error: state.error);
  }

  void _fail(String message) => state = CoachChat(messages: state.messages, error: message);
}

final coachControllerProvider = NotifierProvider<CoachController, CoachChat>(CoachController.new);
