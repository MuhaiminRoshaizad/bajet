import 'package:bajet/core/database/app_database.dart' show AppDatabase;
import 'package:bajet/features/checkin/data/drift_checkin_repository.dart';
import 'package:bajet/features/checkin/domain/checkin.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late DriftCheckinRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = DriftCheckinRepository(db);
  });
  tearDown(() => db.close());

  Checkin on(int day, {int balance = 100000, int? left}) =>
      Checkin(checkedOn: DateTime.utc(2026, 7, day), balance: balance, matched: true, allowanceSpent: 2150, leftAfterBuying: left, nextTarget: balance - 3000);

  test('lists check-ins newest first, with every figure kept', () async {
    await repo.save(on(5, left: 52000));
    await repo.save(on(12, balance: 98000));
    final saved = await repo.watchCheckins().first;
    expect(saved.map((c) => c.checkedOn.day), [12, 5]);
    expect((saved.last.balance, saved.last.leftAfterBuying, saved.last.nextTarget, saved.first.leftAfterBuying), (100000, 52000, 97000, null));
    expect(saved.last.targetOn, DateTime.utc(2026, 7, 12));
  });

  test('finishing again the same day replaces that day', () async {
    await repo.save(on(5));
    await repo.save(on(5, balance: 99000));
    expect((await repo.watchCheckins().first).single.balance, 99000);
  });
}
