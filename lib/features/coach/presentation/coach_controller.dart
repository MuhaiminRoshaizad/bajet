import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../../core/dates/clock.dart';
import '../../accounts/presentation/account_providers.dart';
import '../../ledger/presentation/ledger_providers.dart';
import '../../plan/presentation/plan_providers.dart';
import '../domain/coach_answer.dart';
import '../domain/coach_client.dart';
import '../domain/coach_guard.dart';
import '../domain/coach_lookups.dart';
import '../domain/coach_memory.dart';
import '../domain/coach_prompt.dart';
import '../domain/coach_proposals.dart';
import '../domain/coach_settings.dart';
import '../domain/coach_thread.dart';
import 'coach_avatar.dart';
import 'coach_chats.dart';
import 'coach_providers.dart';

/// What the coach's face is doing in one chat: thinking while it waits,
/// then reacting to what happened. Each chat keeps its own.
class CoachMoodController extends Notifier<CoachMood> {
  CoachMoodController(this.chat);

  final int chat;

  @override
  CoachMood build() => CoachMood.idle;

  void set(CoachMood mood) => state = mood;
}

final coachMoodProvider = NotifierProvider.family<CoachMoodController, CoachMood, int>(CoachMoodController.new);

/// How the coach has been put upon across every chat, so starting a new
/// chat is no way round it: messages turned away, and the pause after spam.
class CoachPushback {
  var declined = 0;
  final spam = SpamPause();
}

final coachPushbackProvider = Provider<CoachPushback>((ref) => CoachPushback());

class CoachChat {
  const CoachChat({this.messages = const [], this.sending = false, this.reading, this.error});

  final List<CoachMessage> messages;
  final bool sending;

  /// What the coach is looking at while it works on an answer, such as
  /// "This week"; null before its first lookup.
  final String? reading;

  /// Why the last question got no answer, worded for the user.
  final String? error;

  /// The last question is waiting for an answer that failed.
  bool get canRetry => error != null && messages.isNotEmpty && messages.last.fromUser;
}

/// One chat with the coach. Its messages come from [coachChatsProvider],
/// which keeps them; this runs the asking and answering in it, in its own
/// coach's face and voice.
class CoachController extends Notifier<CoachChat> {
  CoachController(this.chat);

  final int chat;

  var _sending = false;
  String? _reading, _error;

  @override
  CoachChat build() {
    final messages = ref.watch(coachChatsProvider.select((c) => c.byId(chat)?.messages ?? const <CoachMessage>[]));
    settled ??= messages.length;
    return CoachChat(messages: messages, sending: _sending, reading: _reading, error: _error);
  }

  /// Repeats in a row, so the coach's replies to them get firmer each time.
  var _repeats = 0;
  DateTime? _lastAskedAt;

  /// Cards whose change is being made, so a second tap meanwhile does not
  /// make it twice.
  final _confirming = <(int, int)>{};

  DateTime get _now => ref.read(clockProvider)();

  /// How many of the messages, from the top, were there when the chat was
  /// first shown; the screen springs in only the rest.
  int? settled;

  CoachThread? get _thread => ref.read(coachChatsProvider).byId(chat);
  CoachFace get _face => _thread?.face ?? CoachFace.bajety;
  CoachPersonality get _personality => _thread?.personality ?? CoachPersonality.friendly;
  CoachChatsController get _chats => ref.read(coachChatsProvider.notifier);
  CoachPushback get _pushback => ref.read(coachPushbackProvider);

  void _mood(CoachMood mood) => ref.read(coachMoodProvider(chat).notifier).set(mood);

  /// A message turned away or asked again: the knows-too-much voice stares,
  /// the others look concerned.
  CoachMood get _unimpressed => _personality == CoachPersonality.seesEverything ? CoachMood.stare : CoachMood.concerned;

  void _set({required bool sending, String? reading, String? error}) {
    _sending = sending;
    _reading = reading;
    _error = error;
    state = CoachChat(messages: state.messages, sending: sending, reading: reading, error: error);
  }

  Future<void> ask(String question) async {
    final text = question.trim();
    if (text.isEmpty || _sending) return;
    // Busy from the first moment, so a second send while this one is still
    // being saved is not taken as another question.
    _set(sending: true);
    final now = _now;
    final messages = state.messages;
    final answered = messages.length >= 2 && !messages.last.fromUser;
    final previous = answered ? messages.lastWhere((m) => m.fromUser).text : null;
    final repeat = isRepeat(text, previous, now.difference(_lastAskedAt ?? now));
    _lastAskedAt = now;
    await _add(CoachMessage(fromUser: true, text: text, sentAt: now));
    if (repeat) {
      // Asked again within a minute: answered on the phone, costing nothing
      // and counting against nothing.
      _mood(_unimpressed);
      return _reply(repeatLine(_personality, _repeats++));
    }
    _repeats = 0;
    if (_pushback.spam.isOn(now)) {
      _mood(_unimpressed);
      return _reply(pauseLine(_personality));
    }
    await _answer();
  }

  /// Sends the unanswered last question again.
  Future<void> retry() async {
    if (state.canRetry && !_sending) await _answer();
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
    _set(sending: true);
    _mood(CoachMood.thinking);
    try {
      final client = ref.read(coachClientProvider);
      final kind = await gate(client, key, state.messages.last.text);
      // Turned away on the phone, in the coach's own voice: the message never
      // reaches the coach and costs no question.
      if (kind == GateKind.offTopic || kind == GateKind.attack) {
        _pushback.spam.turnedAway(_now);
        _mood(_unimpressed);
        return _reply(declineLine(_personality, _pushback.declined++));
      }
      _pushback.spam.heard();
      final said = spoken(state.messages);
      final conversation = forModel(said);
      // What the coach can search: this chat's earlier messages and every
      // other chat's.
      final older = [
        ...said.sublist(0, said.length - conversation.length),
        for (final t in ref.read(coachChatsProvider).threads)
          if (t.id != chat) ...spoken(t.messages),
      ];
      final cards = <CoachCard>[];
      final answer = await coachAnswer(
        client: client,
        apiKey: key,
        system: coachSystemPrompt(today, _personality),
        conversation: conversation,
        tools: [...coachLookups, if (older.isNotEmpty) pastChatsLookup, ...proposalTools],
        lookup: (name, input) {
          final LookupResult result;
          if (name == pastChatsLookup.name) {
            result = searchPastChats(input, older);
          } else if (!name.startsWith('bajet_propose_')) {
            result = runLookup(name, input, data);
          } else {
            final (r, proposal) = propose(name, input, data);
            if (proposal != null) cards.add(CoachCard(proposal));
            result = r;
          }
          if (!result.failed) _set(sending: true, reading: result.label);
          return result;
        },
      );
      await store.recordUse(today);
      ref.invalidate(coachUsedTodayProvider);
      if (replyLooksWrong(answer.text)) {
        _mood(_unimpressed);
        return _reply(declineLine(_personality, _pushback.declined++));
      }
      _mood(CoachMood.happy);
      await _add(CoachMessage(fromUser: false, text: answer.text, looked: answer.looked, cards: cards, sentAt: _now, face: _face));
    } on CoachException catch (e) {
      _fail(e.message);
    }
  }

  /// Does what card [card] of message [message] suggested.
  Future<void> confirm(int message, int card) async {
    final c = state.messages[message].cards[card];
    if (c.state != CardState.waiting || !_confirming.add((message, card))) return;
    try {
      await _make(message, card, c);
    } finally {
      _confirming.remove((message, card));
    }
  }

  /// Makes the change card [card] of message [message] suggested.
  Future<void> _make(int message, int card, CoachCard c) async {
    final int? undoId;
    switch (c.proposal) {
      case LogProposal(:final draft):
        undoId = await ref.read(ledgerRepositoryProvider).add(draft);
      case MoveProposal(:final fromId, :final toId, :final amount, :final day, :final note):
        undoId = await ref.read(accountRepositoryProvider).transfer(fromId: fromId, toId: toId, amount: amount, day: day, note: note);
      case BillPaidProposal(:final item):
        // A card waits in the remembered chat for as long as the user likes;
        // a bill paid meanwhile from the Plan tab is not paid again.
        final paid = await ref.read(planRepositoryProvider).confirmRecurring(item.id, due: item.nextDue, paidOn: ref.read(todayProvider));
        if (!paid) return _setCard(message, card, c.copyWith(state: CardState.outdated));
        undoId = null;
    }
    _mood(CoachMood.cheer);
    await _setCard(message, card, c.copyWith(state: CardState.done, undoId: undoId));
  }

  /// Switches this chat's coach. The chat stays; the new face says hello in
  /// it, so the switch is part of the record.
  Future<void> switchFace(CoachFace face) async {
    if (face == _face) return;
    await _chats.setCoach(chat, face: face);
    if (state.messages.isEmpty) return;
    _mood(CoachMood.hello);
    await _add(CoachMessage(
      fromUser: false,
      text: face == CoachFace.bajety
          ? 'bajety here. Is that a new Verity? No lah. I remember everything we said.'
          : "Hi, ${face.label} here. I've read our chat, so carry on.",
      sentAt: _now,
      face: face,
    ));
  }

  /// Switches this chat's personality. A line in the chat says so, so a
  /// change of tone has a reason anyone scrolling back can see.
  Future<void> setPersonality(CoachPersonality personality) async {
    if (personality == _personality) return;
    await _chats.setCoach(chat, personality: personality);
    if (state.messages.isEmpty) return;
    await _add(CoachMessage.note('${_face.label} is now ${personality.label}', sentAt: _now));
  }

  Future<void> decline(int message, int card) async {
    final c = state.messages[message].cards[card];
    if (c.state == CardState.waiting) await _setCard(message, card, c.copyWith(state: CardState.declined));
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
    await _setCard(message, card, c.copyWith(state: CardState.undone));
  }

  Future<void> _setCard(int message, int card, CoachCard updated) {
    final m = state.messages[message];
    return _chats.replace(chat, message, m.withCards([...m.cards]..[card] = updated));
  }

  /// Adds [m] to this chat; a reply ends the wait for one, in the same
  /// frame as it appears.
  Future<void> _add(CoachMessage m) async {
    if (!m.fromUser) {
      _sending = false;
      _reading = null;
    }
    await _chats.add(chat, m);
  }

  Future<void> _reply(String text) => _add(CoachMessage(fromUser: false, text: text, sentAt: _now, face: _face));

  void _fail(String message) {
    _mood(CoachMood.concerned);
    _set(sending: false, error: message);
  }
}

final coachControllerProvider = NotifierProvider.family<CoachController, CoachChat, int>(CoachController.new);
