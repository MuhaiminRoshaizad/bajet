import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../accounts/presentation/account_providers.dart';
import '../../ledger/presentation/ledger_providers.dart';
import '../../plan/presentation/plan_providers.dart';
import '../domain/coach_answer.dart';
import '../domain/coach_client.dart';
import '../domain/coach_guard.dart';
import '../domain/coach_lookups.dart';
import '../domain/coach_prompt.dart';
import '../domain/coach_proposals.dart';
import '../domain/coach_settings.dart';
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

  /// Messages turned away today and repeats in a row, so the coach's
  /// replies to them get firmer each time.
  var _declined = 0, _repeats = 0;
  DateTime? _lastAskedAt;

  CoachPersonality get _personality => (ref.read(coachSettingsProvider).value ?? const CoachSettings()).personality;

  Future<void> ask(String question) async {
    final text = question.trim();
    if (text.isEmpty || state.sending) return;
    final now = DateTime.now();
    final answered = state.messages.length >= 2 && !state.messages.last.fromUser;
    final previous = answered ? state.messages.lastWhere((m) => m.fromUser).text : null;
    final repeat = isRepeat(text, previous, now.difference(_lastAskedAt ?? now));
    _lastAskedAt = now;
    state = CoachChat(messages: [...state.messages, CoachMessage(fromUser: true, text: text)]);
    if (repeat) {
      // Asked again within a minute: answered on the phone, costing nothing
      // and counting against nothing.
      return _reply(repeatLine(_personality, _repeats++));
    }
    _repeats = 0;
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
      final client = ref.read(coachClientProvider);
      final kind = await gate(client, key, state.messages.last.text);
      // Turned away on the phone, in the coach's own voice: the message never
      // reaches the coach and costs no question.
      if (kind == GateKind.offTopic || kind == GateKind.attack) return _reply(declineLine(_personality, _declined++));
      final cards = <CoachCard>[];
      final answer = await coachAnswer(
        client: client,
        apiKey: key,
        system: coachSystemPrompt(today, _personality),
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
      if (replyLooksWrong(answer.text)) return _reply(declineLine(_personality, _declined++));
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

  void _reply(String text) => state = CoachChat(messages: [...state.messages, CoachMessage(fromUser: false, text: text)]);

  void _fail(String message) => state = CoachChat(messages: state.messages, error: message);
}

final coachControllerProvider = NotifierProvider<CoachController, CoachChat>(CoachController.new);
