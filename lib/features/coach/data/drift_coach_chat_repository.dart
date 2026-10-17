import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart' as db;
import '../domain/coach_client.dart';
import '../domain/coach_memory.dart';
import '../domain/coach_proposals.dart';
import '../domain/coach_settings.dart';

class DriftCoachChatRepository implements CoachChatRepository {
  DriftCoachChatRepository(this._db);

  final db.AppDatabase _db;

  @override
  Future<List<CoachMessage>> load() async {
    final rows = await (_db.select(_db.coachMessages)..orderBy([(m) => OrderingTerm(expression: m.id)])).get();
    return [for (final r in rows) _message(r)];
  }

  @override
  Future<int> add(CoachMessage m) => _db.into(_db.coachMessages).insert(_row(m));

  @override
  Future<void> saveCards(int id, CoachMessage m) =>
      (_db.update(_db.coachMessages)..where((r) => r.id.equals(id))).write(db.CoachMessagesCompanion(cards: Value(_cards(m.cards))));

  @override
  Future<List<CoachMessage>> clear() => _db.transaction(() async {
        final all = await load();
        await _db.delete(_db.coachMessages).go();
        return all;
      });

  @override
  Future<void> restore(List<CoachMessage> messages) => _db.batch((b) => b.insertAll(_db.coachMessages, [
        for (final m in messages) _row(m).copyWith(id: m.id == null ? const Value.absent() : Value(m.id!)),
      ]));

  db.CoachMessagesCompanion _row(CoachMessage m) => db.CoachMessagesCompanion.insert(
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
