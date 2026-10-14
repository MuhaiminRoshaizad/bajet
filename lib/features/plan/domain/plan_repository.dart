import 'plan_models.dart';

class PlanSettings {
  const PlanSettings({
    required this.openingBalance,
    required this.openingDate,
    required this.weeklyCap,
    required this.buffer,
  });

  final int openingBalance;
  final DateTime openingDate;
  final int weeklyCap;
  final int buffer;
}

abstract interface class PlanRepository {
  /// Null until first-run setup.
  Stream<PlanSettings?> watchSettings();
  Future<void> saveSettings(PlanSettings settings);

  Stream<List<WeeklyRule>> watchRules();
  Future<void> saveRule(WeeklyRule rule);

  Stream<List<RecurringItem>> watchRecurring();
  Future<int> addRecurring({
    required String name,
    required bool isIncome,
    required int amount,
    required String categoryKey,
    required DateTime nextDue,
  });

  /// Pausing keeps the item and its history but stops it being projected or
  /// offered for confirmation. Items are paused rather than deleted because
  /// confirmed entries refer to them.
  Future<void> setRecurringActive(int id, {required bool active});

  /// Logs the occurrence due on [nextDue] as a real entry dated [paidOn] and
  /// moves the item's next due date forward one month, in one transaction.
  Future<void> confirmRecurring(int id, {required DateTime paidOn});

  Stream<List<PlannedEvent>> watchEvents();
  Future<int> addEvent({
    required String name,
    required bool isIncome,
    required int amount,
    required String categoryKey,
    required DateTime date,
    bool countInProjection = true,
  });

  /// Marks a one-off event as having happened, so the projection stops
  /// counting it. Logging the money itself stays a normal entry.
  Future<void> setEventDone(int id, {required bool done});

  /// Active goals, highest priority first.
  Stream<List<Goal>> watchActiveGoals();

  /// Goals marked bought, most recent first.
  Stream<List<Goal>> watchAchievedGoals();

  /// Sets active goals' priorities to follow [ids], first is highest.
  Future<void> reorderGoals(List<int> ids);
  Future<int> addGoal({required String name, required int price, required DateTime targetDate, int priority = 1});

  /// Logs the purchase as an expense on [on] and marks the goal achieved, in
  /// one transaction, so it leaves the active goals.
  Future<void> markGoalBought(int id, {required DateTime on});
}
