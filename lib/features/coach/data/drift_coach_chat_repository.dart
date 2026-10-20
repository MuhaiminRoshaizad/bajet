import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart' as db;
import '../domain/coach_client.dart';
import '../domain/coach_memory.dart';
import '../domain/coach_proposals.dart';
import '../domain/coach_settings.dart';
import '../domain/coach_thread.dart';

class DriftCoachChatRepository implements CoachChatRepository {
  DriftCoachChatRepository(this._db);

  final db.AppDatabase _db;

  @override
  Future<List<CoachThread>> load() async {
    final threads = await (_db.select(_db.coachThreads)..orderBy([(t) => OrderingTerm(expression: t.id)])).get();
    final rows = await (_db.select(_db.coachMessages)..orderBy([(m) => OrderingTerm(expression: m.id)])).get();
    final said = <int, List<CoachMessage>>{};
    for (final r in rows) {
      (said[r.threadId] ??= []).add(_message(r));
    }
    return [for (final t in threads) _thread(t, said[t.id] ?? const [])];
  }

  @override
  Future<int> createThread(CoachThread t) => _db.into(_db.coachThreads).insert(_threadRow(t));

  @override
  Future<void> saveThread(CoachThread t) =>
      (_db.update(_db.coachThreads)..where((r) => r.id.equals(t.id))).write(_threadRow(t));

  @override
  Future<void> deleteThread(int id) => _db.transaction(() async {
        await (_db.delete(_db.coachMessages)..where((m) => m.threadId.equals(id))).go();
        await (_db.delete(_db.coachThreads)..where((t) => t.id.equals(id))).go();
      });

  @override
  Future<int> add(int threadId, CoachMessage m) => _db.into(_db.coachMessages).insert(_row(threadId, m));

  @override
  Future<void> saveCards(int id, CoachMessage m) =>
      (_db.update(_db.coachMessages)..where((r) => r.id.equals(id))).write(db.CoachMessagesCompanion(cards: Value(_cards(m.cards))));

  @override
  Future<List<CoachThread>> clear() => _db.transaction(() async {
        final all = await load();
        await _db.delete(_db.coachMessages).go();
        await _db.delete(_db.coachThreads).go();
        return all;
      });

  @override
  Future<void> restore(List<CoachThread> threads) => _db.batch((b) {
        b.insertAll(_db.coachThreads, [for (final t in threads) _threadRow(t).copyWith(id: Value(t.id))]);
        b.insertAll(_db.coachMessages, [
          for (final t in threads)
            for (final m in t.messages) _row(t.id, m).copyWith(id: m.id == null ? const Value.absent() : Value(m.id!)),
        ]);
      });

  db.CoachThreadsCompanion _threadRow(CoachThread t) => db.CoachThreadsCompanion.insert(
        title: t.title,
        pinned: Value(t.pinned),
        face: t.face.name,
        personality: t.personality.name,
        createdAt: t.createdAt.millisecondsSinceEpoch,
      );

  CoachThread _thread(db.CoachThread r, List<CoachMessage> messages) => CoachThread(
        id: r.id,
        title: r.title,
        pinned: r.pinned,
        // A key from a newer version this one does not know falls back to
        // the default rather than failing.
        face: CoachFace.values.asNameMap()[r.face] ?? CoachFace.bajety,
        personality: CoachPersonality.values.asNameMap()[r.personality] ?? CoachPersonality.friendly,
        createdAt: DateTime.fromMillisecondsSinceEpoch(r.createdAt),
        messages: messages,
      );

  db.CoachMessagesCompanion _row(int threadId, CoachMessage m) => db.CoachMessagesCompanion.insert(
        threadId: threadId,
        sentAt: (m.sentAt ?? DateTime.now()).millisecondsSinceEpoch,
        fromUser: m.fromUser,
        body: m.text,
        face: Value(m.face?.name),
        looked: Value(m.looked.join('\n')),
        cards: Value(_cards(m.cards)),
        note: Value(m.note),
      );

  CoachMessage _message(db.CoachMessage r) {
    final sentAt = DateTime.fromMillisecondsSinceEpoch(r.sentAt);
    if (r.note) return CoachMessage.note(r.body, sentAt: sentAt, id: r.id);
    return CoachMessage(
      id: r.id,
      sentAt: sentAt,
      fromUser: r.fromUser,
      text: r.body,
      face: CoachFace.values.asNameMap()[r.face],
      looked: r.looked.isEmpty ? const [] : r.looked.split('\n'),
      cards: r.cards.isEmpty
          ? const []
          : [for (final j in (jsonDecode(r.cards) as List).cast<Map<String, Object?>>()) ?cardFromJson(j)],
    );
  }

  String _cards(List<CoachCard> cards) => cards.isEmpty ? '' : jsonEncode([for (final c in cards) cardToJson(c)]);
}
