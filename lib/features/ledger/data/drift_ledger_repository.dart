import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../domain/ledger_models.dart' as domain;
import '../domain/ledger_repository.dart';

class DriftLedgerRepository implements LedgerRepository {
  DriftLedgerRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<List<domain.Category>> watchCategories() {
    final q = _db.select(_db.categories)
      ..where((c) => c.archived.equals(false))
      ..orderBy([(c) => OrderingTerm(expression: c.sortOrder)]);
    return q.watch().map((rows) => [
          for (final r in rows)
            domain.Category(
              key: r.key,
              label: r.label,
              isIncome: r.kind == EntryKind.income,
              tint: r.tint,
              isFixed: r.isFixed,
            ),
        ]);
  }

  @override
  Stream<List<domain.Entry>> watchSince(DateTime from) {
    final q = _db.select(_db.entries)
      ..where((e) => e.occurredOn.isBiggerOrEqualValue(const DayConverter().toSql(from)))
      ..orderBy([
        (e) => OrderingTerm.desc(e.occurredOn),
        (e) => OrderingTerm.desc(e.id),
      ]);
    return q.watch().map((rows) => rows.map(_toDomain).toList());
  }

  @override
  Stream<int?> watchBalance() {
    // ISO day strings compare correctly as text, so the date filter stays in SQL.
    final query = _db.customSelect(
      'SELECT s.opening_balance + COALESCE(SUM(CASE WHEN e.kind = ? THEN e.amount ELSE -e.amount END), 0) AS balance '
      'FROM app_settings s LEFT JOIN entries e ON e.occurred_on >= s.opening_date '
      'GROUP BY s.id',
      variables: [Variable.withString(EntryKind.income.name)],
      readsFrom: {_db.appSettings, _db.entries},
    );
    return query.watch().map((rows) => rows.isEmpty ? null : rows.single.read<int>('balance'));
  }

  @override
  Future<int> add(domain.EntryDraft d) => _db.into(_db.entries).insert(
        EntriesCompanion.insert(
          occurredOn: d.day,
          kind: d.isIncome ? EntryKind.income : EntryKind.expense,
          amount: d.amount,
          categoryKey: d.categoryKey,
          label: Value(_blankToNull(d.label)),
          note: Value(_blankToNull(d.note)),
          receipt: Value(d.receipt),
          plannedEventId: Value(d.event?.eventId),
          plannedEventOn: Value(d.event?.on),
        ),
      );

  @override
  Future<void> update(domain.Entry e) async {
    await (_db.update(_db.entries)..where((t) => t.id.equals(e.id))).write(
      EntriesCompanion(
        occurredOn: Value(e.day),
        kind: Value(e.isIncome ? EntryKind.income : EntryKind.expense),
        amount: Value(e.amount),
        categoryKey: Value(e.categoryKey),
        label: Value(_blankToNull(e.label)),
        note: Value(_blankToNull(e.note)),
        receipt: Value(e.receipt),
        plannedEventId: Value(e.event?.eventId),
        plannedEventOn: Value(e.event?.on),
      ),
    );
  }

  @override
  Future<void> delete(int id) => (_db.delete(_db.entries)..where((t) => t.id.equals(id))).go();

  @override
  Future<void> restore(domain.Entry e) => _db.into(_db.entries).insert(
        EntriesCompanion.insert(
          id: Value(e.id),
          occurredOn: e.day,
          kind: e.isIncome ? EntryKind.income : EntryKind.expense,
          amount: e.amount,
          categoryKey: e.categoryKey,
          label: Value(e.label),
          note: Value(e.note),
          receipt: Value(e.receipt),
          plannedEventId: Value(e.event?.eventId),
          plannedEventOn: Value(e.event?.on),
        ),
      );

  domain.Entry _toDomain(Entry r) => domain.Entry(
        id: r.id,
        day: r.occurredOn,
        isIncome: r.kind == EntryKind.income,
        amount: r.amount,
        categoryKey: r.categoryKey,
        label: r.label,
        note: r.note,
        receipt: r.receipt,
        event: r.plannedEventId == null || r.plannedEventOn == null ? null : domain.EventLink(r.plannedEventId!, r.plannedEventOn!),
      );
}

class DriftFavouriteRepository implements FavouriteRepository {
  DriftFavouriteRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<List<domain.Favourite>> watchAll() {
    final q = _db.select(_db.favourites)..orderBy([(f) => OrderingTerm(expression: f.sortOrder), (f) => OrderingTerm(expression: f.id)]);
    return q.watch().map((rows) => [
          for (final r in rows) domain.Favourite(id: r.id, label: r.label, categoryKey: r.categoryKey, amount: r.amount),
        ]);
  }

  @override
  Future<int> add({required String label, required String categoryKey, required int amount}) =>
      _db.into(_db.favourites).insert(FavouritesCompanion.insert(label: label.trim(), categoryKey: categoryKey, amount: amount));

  @override
  Future<void> update(domain.Favourite f) async {
    await (_db.update(_db.favourites)..where((t) => t.id.equals(f.id))).write(
      FavouritesCompanion(label: Value(f.label.trim()), categoryKey: Value(f.categoryKey), amount: Value(f.amount)),
    );
  }

  @override
  Future<void> delete(int id) => (_db.delete(_db.favourites)..where((t) => t.id.equals(id))).go();
}

String? _blankToNull(String? s) => (s == null || s.trim().isEmpty) ? null : s.trim();
