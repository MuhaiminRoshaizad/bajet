import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../ledger/domain/ledger_models.dart' show goalCategoryKey;
import '../domain/plan_models.dart' as domain;
import '../domain/plan_repository.dart';

class DriftPlanRepository implements PlanRepository {
  DriftPlanRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<PlanSettings?> watchSettings() => _db.select(_db.appSettings).watchSingleOrNull().map(
        (r) => r == null
            ? null
            : PlanSettings(openingBalance: r.openingBalance, openingDate: r.openingDate, weeklyCap: r.weeklyCap, buffer: r.buffer),
      );

  @override
  Future<void> saveSettings(PlanSettings s) => _db.into(_db.appSettings).insertOnConflictUpdate(
        AppSettingsCompanion.insert(
          id: const Value(1),
          openingBalance: s.openingBalance,
          openingDate: s.openingDate,
          weeklyCap: s.weeklyCap,
          buffer: s.buffer,
        ),
      );

  @override
  Stream<List<domain.WeeklyRule>> watchRules() {
    final q = _db.select(_db.weeklyRules)..orderBy([(r) => OrderingTerm(expression: r.weekday)]);
    return q.watch().map((rows) => [
          for (final r in rows)
            domain.WeeklyRule(
              weekday: r.weekday,
              label: r.label,
              type: domain.DayType.values.byName(r.dayType.name),
              plannedSpend: r.plannedSpend,
              isFastingDay: r.isFastingDay,
            ),
        ]);
  }

  @override
  Future<void> saveRule(domain.WeeklyRule rule) => _db.into(_db.weeklyRules).insertOnConflictUpdate(
        WeeklyRulesCompanion.insert(
          weekday: Value(rule.weekday),
          label: rule.label,
          dayType: RhythmDayType.values.byName(rule.type.name),
          plannedSpend: Value(rule.plannedSpend),
          isFastingDay: Value(rule.isFastingDay),
        ),
      );

  @override
  Stream<List<domain.RecurringItem>> watchRecurring() => _db.select(_db.recurringItems).watch().map((rows) => [
        for (final r in rows)
          domain.RecurringItem(
            id: r.id,
            name: r.name,
            amount: r.amount,
            categoryKey: r.categoryKey,
            isIncome: r.kind == EntryKind.income,
            nextDue: r.nextDue,
            windowDays: r.windowDays,
            active: r.active,
          ),
      ]);

  @override
  Future<int> addRecurring({
    required String name,
    required bool isIncome,
    required int amount,
    required String categoryKey,
    required DateTime nextDue,
    int windowDays = 0,
  }) =>
      _db.into(_db.recurringItems).insert(
            RecurringItemsCompanion.insert(
              name: name.trim(),
              kind: isIncome ? EntryKind.income : EntryKind.expense,
              amount: amount,
              categoryKey: categoryKey,
              nextDue: nextDue,
              windowDays: Value(windowDays),
            ),
          );

  @override
  Future<void> updateRecurring(domain.RecurringItem item) async {
    await (_db.update(_db.recurringItems)..where((r) => r.id.equals(item.id))).write(RecurringItemsCompanion(
          name: Value(item.name.trim()),
          amount: Value(item.amount),
          categoryKey: Value(item.categoryKey),
          nextDue: Value(item.nextDue),
          windowDays: Value(item.windowDays),
        ));
  }

  @override
  Future<void> setRecurringActive(int id, {required bool active}) async {
    await (_db.update(_db.recurringItems)..where((r) => r.id.equals(id))).write(RecurringItemsCompanion(active: Value(active)));
  }

  @override
  Future<void> confirmRecurring(int id, {required DateTime paidOn}) => _db.transaction(() async {
        final item = await (_db.select(_db.recurringItems)..where((r) => r.id.equals(id))).getSingle();
        await _db.into(_db.entries).insert(
              EntriesCompanion.insert(
                occurredOn: paidOn,
                kind: item.kind,
                amount: item.amount,
                categoryKey: item.categoryKey,
                label: Value(item.name),
                recurringItemId: Value(item.id),
              ),
            );
        final due = item.nextDue;
        await (_db.update(_db.recurringItems)..where((r) => r.id.equals(id)))
            .write(RecurringItemsCompanion(nextDue: Value(DateTime.utc(due.year, due.month + 1, due.day))));
      });

  @override
  Stream<List<domain.PlannedEvent>> watchEvents() => _db.select(_db.plannedEvents).watch().map((rows) => [
        for (final r in rows)
          domain.PlannedEvent(
            id: r.id,
            name: r.name,
            amount: r.amount,
            isIncome: r.kind == EntryKind.income,
            date: r.dueOn,
            countInProjection: r.countInProjection,
            done: r.done,
          ),
      ]);

  @override
  Future<int> addEvent({
    required String name,
    required bool isIncome,
    required int amount,
    required String categoryKey,
    required DateTime date,
    bool countInProjection = true,
  }) =>
      _db.into(_db.plannedEvents).insert(
            PlannedEventsCompanion.insert(
              name: name.trim(),
              kind: isIncome ? EntryKind.income : EntryKind.expense,
              amount: amount,
              categoryKey: categoryKey,
              dueOn: date,
              countInProjection: Value(countInProjection),
            ),
          );

  @override
  Future<void> setEventDone(int id, {required bool done}) async {
    await (_db.update(_db.plannedEvents)..where((e) => e.id.equals(id))).write(PlannedEventsCompanion(done: Value(done)));
  }

  @override
  Stream<List<domain.Goal>> watchActiveGoals() {
    final q = _db.select(_db.goals)
      ..where((g) => g.status.equalsValue(GoalStatus.active))
      ..orderBy([(g) => OrderingTerm(expression: g.priority), (g) => OrderingTerm(expression: g.targetDate)]);
    return q.watch().map((rows) => [
          for (final r in rows) domain.Goal(id: r.id, name: r.name, price: r.price, targetDate: r.targetDate, priority: r.priority),
        ]);
  }

  @override
  Stream<List<domain.Goal>> watchAchievedGoals() {
    final q = _db.select(_db.goals)
      ..where((g) => g.status.equalsValue(GoalStatus.achieved))
      ..orderBy([(g) => OrderingTerm(expression: g.achievedOn, mode: OrderingMode.desc)]);
    return q.watch().map((rows) => [
          for (final r in rows)
            domain.Goal(id: r.id, name: r.name, price: r.price, targetDate: r.targetDate, priority: r.priority, achievedOn: r.achievedOn),
        ]);
  }

  @override
  Future<void> reorderGoals(List<int> ids) => _db.transaction(() async {
        for (final (i, id) in ids.indexed) {
          await (_db.update(_db.goals)..where((g) => g.id.equals(id))).write(GoalsCompanion(priority: Value(i + 1)));
        }
      });

  @override
  Future<int> addGoal({required String name, required int price, required DateTime targetDate, int priority = 1}) =>
      _db.into(_db.goals).insert(GoalsCompanion.insert(name: name.trim(), price: price, targetDate: targetDate, priority: Value(priority)));

  @override
  Future<void> markGoalBought(int id, {required DateTime on}) => _db.transaction(() async {
        final goal = await (_db.select(_db.goals)..where((g) => g.id.equals(id))).getSingle();
        await _db.into(_db.entries).insert(
              EntriesCompanion.insert(occurredOn: on, kind: EntryKind.expense, amount: goal.price, categoryKey: goalCategoryKey, label: Value(goal.name)),
            );
        await (_db.update(_db.goals)..where((g) => g.id.equals(id)))
            .write(GoalsCompanion(status: const Value(GoalStatus.achieved), achievedOn: Value(on)));
      });
}
