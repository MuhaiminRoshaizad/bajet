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
  Future<List<CoachMessage>> load() async {
    final rows = await (_db.select(_db.coachMessages)..orderBy([(m) => OrderingTerm(expression: m.id)])).get();
    return [for (final r in rows) _message(r)];
  }

  @override
  Future<int> add(CoachMessage m) async => _db.into(_db.coachMessages).insert(_row(await _chatFor(m), m));

  @override
  Future<void> saveCards(int id, CoachMessage m) =>
      (_db.update(_db.coachMessages)..where((r) => r.id.equals(id))).write(db.CoachMessagesCompanion(cards: Value(_cards(m.cards))));

  @override
  Future<List<CoachMessage>> clear() => _db.transaction(() async {
        final all = await load();
        await _db.delete(_db.coachMessages).go();
        await _db.delete(_db.coachThreads).go();
        return all;
      });

  @override
  Future<void> restore(List<CoachMessage> messages) async {
    if (messages.isEmpty) return;
    final chat = await _chatFor(messages.first);
    await _db.batch((b) => b.insertAll(_db.coachMessages, [
          for (final m in messages) _row(chat, m).copyWith(id: m.id == null ? const Value.absent() : Value(m.id!)),
        ]));
  }

  /// The one chat so far, started from [first] when there is none yet,
  /// named after it and coached as the settings say.
  Future<int> _chatFor(CoachMessage first) async {
    final chat = await (_db.select(_db.coachThreads)..limit(1)).getSingleOrNull();
    if (chat != null) return chat.id;
    final settings = await _db.select(_db.coachSettings).getSingleOrNull();
    return _db.into(_db.coachThreads).insert(db.CoachThreadsCompanion.insert(
          title: chatTitleFrom(first.text),
          face: settings?.face ?? CoachFace.bajety.name,
          personality: settings?.personality ?? 'friendly',
          createdAt: (first.sentAt ?? DateTime.now()).millisecondsSinceEpoch,
        ));
  }

  db.CoachMessagesCompanion _row(int chat, CoachMessage m) => db.CoachMessagesCompanion.insert(
        threadId: chat,
        sentAt: (m.sentAt ?? DateTime.now()).millisecondsSinceEpoch,
        fromUser: m.fromUser,
        body: m.text,
        face: Value(m.face?.name),
        looked: Value(m.looked.join('\n')),
        cards: Value(_cards(m.cards)),
      );

  CoachMessage _message(db.CoachMessage r) => CoachMessage(
        id: r.id,
        sentAt: DateTime.fromMillisecondsSinceEpoch(r.sentAt),
        fromUser: r.fromUser,
        text: r.body,
        face: CoachFace.values.asNameMap()[r.face],
        looked: r.looked.isEmpty ? const [] : r.looked.split('\n'),
        cards: r.cards.isEmpty
            ? const []
            : [for (final j in (jsonDecode(r.cards) as List).cast<Map<String, Object?>>()) ?cardFromJson(j)],
      );

  String _cards(List<CoachCard> cards) => cards.isEmpty ? '' : jsonEncode([for (final c in cards) cardToJson(c)]);
}
