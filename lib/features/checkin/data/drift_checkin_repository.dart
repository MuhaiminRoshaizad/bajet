import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart' as db;
import '../domain/checkin.dart';

class DriftCheckinRepository implements CheckinRepository {
  DriftCheckinRepository(this._db);

  final db.AppDatabase _db;

  @override
  Stream<List<Checkin>> watchCheckins() =>
      (_db.select(_db.checkins)..orderBy([(c) => OrderingTerm.desc(c.checkedOn)])).watch().map((rows) => [for (final r in rows) _checkin(r)]);

  @override
  Future<void> save(Checkin c) => _db.into(_db.checkins).insertOnConflictUpdate(db.CheckinsCompanion.insert(
        checkedOn: c.checkedOn,
        balance: c.balance,
        matched: c.matched,
        untracked: Value(c.untracked),
        startingAdjustment: Value(c.startingAdjustment),
        allowanceSpent: c.allowanceSpent,
        leftAfterBuying: Value(c.leftAfterBuying),
        nextTarget: c.nextTarget,
      ));

  Checkin _checkin(db.Checkin r) => Checkin(
        checkedOn: r.checkedOn,
        balance: r.balance,
        matched: r.matched,
        untracked: r.untracked,
        startingAdjustment: r.startingAdjustment,
        allowanceSpent: r.allowanceSpent,
        leftAfterBuying: r.leftAfterBuying,
        nextTarget: r.nextTarget,
      );
}
