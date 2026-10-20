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
import 'coach_avatar.dart';
import 'coach_providers.dart';

/// What the coach's face is doing: thinking while it waits, then reacting
/// to what happened.
class CoachMoodController extends Notifier<CoachMood> {
  @override
  CoachMood build() => CoachMood.idle;

  void set(CoachMood mood) => state = mood;
}

final coachMoodProvider = NotifierProvider<CoachMoodController, CoachMood>(CoachMoodController.new);

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

/// The conversation on the Coach tab: one ongoing chat, remembered on the
/// phone while the memory switch is on (decision 026), and gone when the
/// app closes while it is off.
class CoachController extends Notifier<CoachChat> {
  @override
  CoachChat build() {
    _load();
    return const CoachChat();
  }

  /// Messages turned away today and repeats in a row, so the coach's
  /// replies to them get firmer each time.
  var _declined = 0, _repeats = 0;
  DateTime? _lastAskedAt;
  final _spam = SpamPause();

  /// Cards whose change is being made, so a second tap meanwhile does not
  /// make it twice.
  final _confirming = <(int, int)>{};

  DateTime get _now => ref.read(clockProvider)();

  /// How many of the messages, from the top, came back from memory or Undo
  /// rather than being said just now; the screen springs in only the rest.
  int settled = 0;

  CoachSettings get _settings => ref.read(coachSettingsProvider).value ?? const CoachSettings();
  CoachPersonality get _personality => _settings.personality;

  void _mood(CoachMood mood) => ref.read(coachMoodProvider.notifier).set(mood);

  /// A message turned away or asked again: the knows-too-much voice stares,
  /// the others look concerned.
  CoachMood get _unimpressed => _personality == CoachPersonality.seesEverything ? CoachMood.stare : CoachMood.concerned;

  Future<void> _load() async {
    final settings = await ref.read(coachSettingsProvider.future);
    if (!settings.remember) return;
    final remembered = await ref.read(coachChatRepositoryProvider).load();
    // Anything said while loading stays after what was remembered.
    settled = remembered.length;
    state = CoachChat(messages: [...remembered, ...state.messages], sending: state.sending, reading: state.reading, error: state.error);
  }

  Future<void> ask(String question) async {
    final text = question.trim();
    if (text.isEmpty || state.sending) return;
    // Busy from the first moment, so a second send while this one is still
    // being saved is not taken as another question.
    state = CoachChat(messages: state.messages, sending: true);
    final now = _now;
    final answered = state.messages.length >= 2 && !state.messages.last.fromUser;
    final previous = answered ? state.messages.lastWhere((m) => m.fromUser).text : null;
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
    if (_spam.isOn(now)) {
      _mood(_unimpressed);
      return _reply(pauseLine(_personality));
    }
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
    _mood(CoachMood.thinking);
    try {
      final client = ref.read(coachClientProvider);
      final kind = await gate(client, key, state.messages.last.text);
      // Turned away on the phone, in the coach's own voice: the message never
      // reaches the coach and costs no question.
      if (kind == GateKind.offTopic || kind == GateKind.attack) {
        _spam.turnedAway(_now);
        _mood(_unimpressed);
        return _reply(declineLine(_personality, _declined++));
      }
      _spam.heard();
      final conversation = forModel(state.messages);
      final older = state.messages.sublist(0, state.messages.length - conversation.length);
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
          if (!result.failed) state = CoachChat(messages: state.messages, sending: true, reading: result.label);
          return result;
        },
      );
      await store.recordUse(today);
      ref.invalidate(coachUsedTodayProvider);
      if (replyLooksWrong(answer.text)) {
        _mood(_unimpressed);
        return _reply(declineLine(_personality, _declined++));
      }
      _mood(CoachMood.happy);
      await _add(CoachMessage(fromUser: false, text: answer.text, looked: answer.looked, cards: cards, sentAt: _now, face: _settings.face));
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

  /// Switches the coach's face. The chat stays; the new face says hello in
  /// it, so the switch is part of the record.
  Future<void> switchFace(CoachFace face) async {
    await ref.read(coachSettingsRepositoryProvider).saveSettings(_settings.copyWith(face: face));
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

  /// Empties the chat and what is remembered of it, and returns what went,
  /// for Undo. The user's entries and figures are never touched.
  Future<List<CoachMessage>> forget() async {
    final gone = state.messages;
    await ref.read(coachChatRepositoryProvider).clear();
    settled = 0;
    state = const CoachChat();
    return gone;
  }

  /// Puts back a chat [forget] took away.
  Future<void> unforget(List<CoachMessage> messages) async {
    if (_settings.remember) await ref.read(coachChatRepositoryProvider).restore(messages);
    settled = messages.length;
    state = CoachChat(messages: [...messages, ...state.messages]);
  }

  /// Turning memory off forgets what was kept, though the chat on screen
  /// stays until the app closes. Turning it on keeps the chat from here.
  Future<void> setRemember(bool remember) async {
    final repo = ref.read(coachChatRepositoryProvider);
    await ref.read(coachSettingsRepositoryProvider).saveSettings(_settings.copyWith(remember: remember));
    if (!remember) {
      await repo.clear();
      state = CoachChat(messages: [
        for (final m in state.messages) CoachMessage(fromUser: m.fromUser, text: m.text, looked: m.looked, cards: m.cards, sentAt: m.sentAt, face: m.face),
      ]);
      return;
    }
    final kept = [for (final m in state.messages) m.withId(await repo.add(m))];
    state = CoachChat(messages: kept, sending: state.sending, error: state.error);
  }

  Future<void> _setCard(int message, int card, CoachCard updated) async {
    final messages = [...state.messages];
    final cards = [...messages[message].cards]..[card] = updated;
    messages[message] = messages[message].withCards(cards);
    state = CoachChat(messages: messages, sending: state.sending, error: state.error);
    final id = messages[message].id;
    if (id != null) await ref.read(coachChatRepositoryProvider).saveCards(id, messages[message]);
  }

  /// Adds [m] to the chat, and to memory while it is on.
  Future<void> _add(CoachMessage m) async {
    // A reply ends the wait for one.
    state = CoachChat(messages: [...state.messages, m], sending: m.fromUser && state.sending);
    if (!_settings.remember) return;
    final id = await ref.read(coachChatRepositoryProvider).add(m);
    final at = state.messages.lastIndexOf(m);
    if (at < 0) return;
    final messages = [...state.messages]..[at] = m.withId(id);
    state = CoachChat(messages: messages, sending: state.sending, reading: state.reading, error: state.error);
  }

  Future<void> _reply(String text) => _add(CoachMessage(fromUser: false, text: text, sentAt: _now, face: _settings.face));

  void _fail(String message) {
    _mood(CoachMood.concerned);
    state = CoachChat(messages: state.messages, error: message);
  }
}

final coachControllerProvider = NotifierProvider<CoachController, CoachChat>(CoachController.new);
