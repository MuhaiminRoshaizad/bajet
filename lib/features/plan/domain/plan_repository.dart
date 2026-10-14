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

  /// Logs the occurrence due on [nextDue] as a real entry dated [paidOn] and
  /// moves the item's next due date forward one month, in one transaction.
  Future<void> confirmRecurring(int id, {required DateTime paidOn});

  Stream<List<PlannedEvent>> watchEvents();

  /// Active goals, highest priority first.
  Stream<List<Goal>> watchActiveGoals();
  Future<int> addGoal({required String name, required int price, required DateTime targetDate, int priority = 1});
}
