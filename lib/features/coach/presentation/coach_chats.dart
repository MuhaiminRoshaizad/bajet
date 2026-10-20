import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/dates/clock.dart';
import '../domain/coach_client.dart';
import '../domain/coach_memory.dart';
import '../domain/coach_settings.dart';
import '../domain/coach_thread.dart';
import 'coach_providers.dart';

class CoachChats {
  const CoachChats({this.threads = const [], this.loaded = false});

  /// Every chat, in the order they were started.
  final List<CoachThread> threads;

  /// Whether the kept chats have been read yet.
  final bool loaded;

  CoachThread? byId(int id) => threads.where((t) => t.id == id).firstOrNull;

  /// The chats as the Coach tab lists them: pinned ones first, then the
  /// most recent. A new chat shows once something is said in it.
  List<CoachThread> get listed => [
        for (final pinned in [true, false])
          ...(threads.where((t) => t.pinned == pinned && t.messages.isNotEmpty).toList()..sort((a, b) => b.lastAt.compareTo(a.lastAt))),
      ];

  /// Every message in every chat, oldest chat first.
  List<CoachMessage> get said => [for (final t in threads) ...t.messages];
}

/// Every chat with the coach, kept on the phone while memory is on
/// (decision 026) and for this session only while it is off. Each change
/// shows at once and is saved behind it.
class CoachChatsController extends Notifier<CoachChats> {
  @override
  CoachChats build() {
    _load();
    return const CoachChats();
  }

  CoachSettings get _settings => ref.read(coachSettingsProvider).value ?? const CoachSettings();

  CoachChatRepository get _repo => _settings.remember ? ref.read(coachChatRepositoryProvider) : ref.read(sessionCoachChatRepositoryProvider);

  Future<void> _load() async {
    await ref.read(coachSettingsProvider.future);
    final kept = <CoachThread>[];
    for (final t in await _repo.load()) {
      // A new chat left before anything was said in it is not kept.
      if (t.messages.isEmpty) {
        await _repo.deleteThread(t.id);
      } else {
        kept.add(t);
      }
    }
    // Anything started while loading stays after what was kept.
    state = CoachChats(threads: [...kept, ...state.threads], loaded: true);
  }

  void _edit(int id, CoachThread Function(CoachThread) change) =>
      state = CoachChats(threads: [for (final t in state.threads) t.id == id ? change(t) : t], loaded: state.loaded);

  /// Starts a chat coached by the defaults in Coach settings, named once its
  /// first question is asked, and returns its id.
  Future<int> start() async {
    final draft = CoachThread(id: 0, title: '', face: _settings.face, personality: _settings.personality, createdAt: ref.read(clockProvider)());
    final id = await _repo.createThread(draft);
    state = CoachChats(threads: [...state.threads, CoachThread(id: id, title: '', face: draft.face, personality: draft.personality, createdAt: draft.createdAt)], loaded: state.loaded);
    return id;
  }

  /// Forgets chat [id] if nothing was said in it, as when it is left new.
  Future<void> discardIfEmpty(int id) async {
    if (state.byId(id)?.messages.isNotEmpty ?? true) return;
    state = CoachChats(threads: [for (final t in state.threads) if (t.id != id) t], loaded: state.loaded);
    await _repo.deleteThread(id);
  }

  /// Adds [m] to chat [id], naming the chat after it when it is the first
  /// question.
  Future<void> add(int id, CoachMessage m) async {
    final named = state.byId(id)?.title.isEmpty == true && m.fromUser;
    _edit(id, (t) => t.copyWith(messages: [...t.messages, m], title: named ? chatTitleFrom(m.text) : null));
    if (named) await _repo.saveThread(state.byId(id)!);
    final saved = m.withId(await _repo.add(id, m));
    _edit(id, (t) => t.copyWith(messages: [for (final s in t.messages) identical(s, m) ? saved : s]));
  }

  /// Puts [m] in place of message [index] of chat [id], keeping its cards.
  Future<void> replace(int id, int index, CoachMessage m) async {
    _edit(id, (t) => t.copyWith(messages: [...t.messages]..[index] = m));
    if (m.id != null) await _repo.saveCards(m.id!, m);
  }

  Future<void> rename(int id, String title) => _save(id, (t) => t.copyWith(title: title));

  Future<void> pin(int id, bool pinned) => _save(id, (t) => t.copyWith(pinned: pinned));

  Future<void> setCoach(int id, {CoachFace? face, CoachPersonality? personality}) => _save(id, (t) => t.copyWith(face: face, personality: personality));

  Future<void> _save(int id, CoachThread Function(CoachThread) change) async {
    _edit(id, change);
    final t = state.byId(id);
    if (t != null) await _repo.saveThread(t);
  }

  /// Forgets chat [id] and returns it, for Undo.
  Future<CoachThread?> delete(int id) async {
    final gone = state.byId(id);
    if (gone == null) return null;
    state = CoachChats(threads: [for (final t in state.threads) if (t.id != id) t], loaded: state.loaded);
    await _repo.deleteThread(id);
    return gone;
  }

  /// Puts back chats [delete] or [forget] took away.
  Future<void> restore(List<CoachThread> threads) async {
    await _repo.restore(threads);
    state = CoachChats(threads: [...state.threads, ...threads]..sort((a, b) => a.id.compareTo(b.id)), loaded: state.loaded);
  }

  /// Forgets every chat and returns them, for Undo. The user's entries and
  /// figures are never touched.
  Future<List<CoachThread>> forget() async {
    final gone = state.threads;
    await _repo.clear();
    state = CoachChats(loaded: state.loaded);
    return gone;
  }

  /// Turning memory off forgets what was kept, though the chats stay for
  /// this session until the app closes. Turning it on keeps them from here.
  Future<void> setRemember(bool remember) async {
    final phone = ref.read(coachChatRepositoryProvider), session = ref.read(sessionCoachChatRepositoryProvider);
    await ref.read(coachSettingsRepositoryProvider).saveSettings(_settings.copyWith(remember: remember));
    if (remember) {
      await phone.restore(await session.clear());
    } else {
      await session.restore(await phone.clear());
    }
  }
}

final coachChatsProvider = NotifierProvider<CoachChatsController, CoachChats>(CoachChatsController.new);
