import '../domain/coach_client.dart';
import '../domain/coach_memory.dart';
import '../domain/coach_thread.dart';

/// Chats kept only while the app runs, for when memory is off: they work
/// like remembered ones, and go when the app closes.
class MemoryCoachChatRepository implements CoachChatRepository {
  final _threads = <CoachThread>[];
  var _nextThread = 1, _nextMessage = 1;

  @override
  Future<List<CoachThread>> load() async => [..._threads];

  @override
  Future<int> createThread(CoachThread t) async {
    final id = _nextThread++;
    _threads.add(CoachThread(id: id, title: t.title, pinned: t.pinned, face: t.face, personality: t.personality, createdAt: t.createdAt));
    return id;
  }

  @override
  Future<void> saveThread(CoachThread t) async => _edit(t.id, (old) => t.copyWith(messages: old.messages));

  @override
  Future<void> deleteThread(int id) async => _threads.removeWhere((t) => t.id == id);

  @override
  Future<int> add(int threadId, CoachMessage m) async {
    final id = _nextMessage++;
    _edit(threadId, (t) => t.copyWith(messages: [...t.messages, m.withId(id)]));
    return id;
  }

  @override
  Future<void> saveCards(int id, CoachMessage m) async {
    for (final t in [..._threads]) {
      if (t.messages.any((s) => s.id == id)) _edit(t.id, (t) => t.copyWith(messages: [for (final s in t.messages) s.id == id ? m : s]));
    }
  }

  @override
  Future<List<CoachThread>> clear() async {
    final gone = [..._threads];
    _threads.clear();
    return gone;
  }

  @override
  Future<void> restore(List<CoachThread> threads) async {
    _threads
      ..addAll(threads)
      ..sort((a, b) => a.id.compareTo(b.id));
    // Ids carry on after the highest put back, so none is given twice.
    for (final t in threads) {
      if (t.id >= _nextThread) _nextThread = t.id + 1;
      for (final m in t.messages) {
        if ((m.id ?? 0) >= _nextMessage) _nextMessage = m.id! + 1;
      }
    }
  }

  void _edit(int id, CoachThread Function(CoachThread) change) {
    final at = _threads.indexWhere((t) => t.id == id);
    if (at >= 0) _threads[at] = change(_threads[at]);
  }
}
