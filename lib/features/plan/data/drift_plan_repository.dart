import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../ledger/domain/ledger_models.dart' show goalCategoryKey;
import '../domain/plan_models.dart' as domain;
import '../domain/plan_models.dart' show RecurringRemoval;
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
  Future<RecurringRemoval> deleteRecurring(int id) => _db.transaction(() async {
        final item = (await watchRecurring().first).firstWhere((r) => r.id == id);
        final linked = await (_db.select(_db.entries)..where((e) => e.recurringItemId.equals(id))).get();
        await (_db.update(_db.entries)..where((e) => e.recurringItemId.equals(id))).write(const EntriesCompanion(recurringItemId: Value(null)));
        await (_db.delete(_db.recurringItems)..where((r) => r.id.equals(id))).go();
        return RecurringRemoval(item, [for (final e in linked) e.id]);
      });

  @override
  Future<void> restoreRecurring(RecurringRemoval removal) => _db.transaction(() async {
        final item = removal.item;
        await _db.into(_db.recurringItems).insert(RecurringItemsCompanion.insert(
              id: Value(item.id),
              name: item.name,
              kind: item.isIncome ? EntryKind.income : EntryKind.expense,
              amount: item.amount,
              categoryKey: item.categoryKey,
              nextDue: item.nextDue,
              windowDays: Value(item.windowDays),
              active: Value(item.active),
            ));
        await (_db.update(_db.entries)..where((e) => e.id.isIn(removal.linkedEntryIds))).write(EntriesCompanion(recurringItemId: Value(item.id)));
      });

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
            categoryKey: r.categoryKey,
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
  Future<void> updateEvent(domain.PlannedEvent event) async {
    await (_db.update(_db.plannedEvents)..where((e) => e.id.equals(event.id))).write(PlannedEventsCompanion(
          name: Value(event.name.trim()),
          amount: Value(event.amount),
          categoryKey: Value(event.categoryKey),
          dueOn: Value(event.date),
          countInProjection: Value(event.countInProjection),
        ));
  }

  @override
  Future<void> deleteEvent(int id) async {
    await (_db.delete(_db.plannedEvents)..where((e) => e.id.equals(id))).go();
  }

  @override
  Future<void> restoreEvent(domain.PlannedEvent event) async {
    await _db.into(_db.plannedEvents).insert(PlannedEventsCompanion.insert(
          id: Value(event.id),
          name: event.name,
          kind: event.isIncome ? EntryKind.income : EntryKind.expense,
          amount: event.amount,
          categoryKey: event.categoryKey,
          dueOn: event.date,
          countInProjection: Value(event.countInProjection),
          done: Value(event.done),
        ));
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

  @override
  Future<void> updateGoal(domain.Goal goal) async {
    await (_db.update(_db.goals)..where((g) => g.id.equals(goal.id)))
        .write(GoalsCompanion(name: Value(goal.name.trim()), price: Value(goal.price), targetDate: Value(goal.targetDate)));
  }

  @override
  Future<void> deleteGoal(int id) async {
    await (_db.delete(_db.goals)..where((g) => g.id.equals(id))).go();
  }

  @override
  Future<void> restoreGoal(domain.Goal goal) async {
    await _db.into(_db.goals).insert(GoalsCompanion.insert(
          id: Value(goal.id),
          name: goal.name,
          price: goal.price,
          targetDate: goal.targetDate,
          priority: Value(goal.priority),
          status: Value(goal.achievedOn == null ? GoalStatus.active : GoalStatus.achieved),
          achievedOn: Value(goal.achievedOn),
        ));
  }
}
