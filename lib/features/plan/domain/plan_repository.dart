import 'plan_models.dart';

/// How the plan runs. Balances are the accounts', each as of [openingDate].
class PlanSettings {
  const PlanSettings({
    required this.openingDate,
    required this.weeklyCap,
    required this.buffer,
    this.needsReserve = 0,
  });

  final DateTime openingDate;
  final int weeklyCap;
  final int buffer;

  /// Set aside each month for needs, which the allowance leaves out; 0 plans
  /// for none.
  final int needsReserve;
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
    int windowDays = 0,
    int? accountId,
  });

  /// Changes an item's name, amount, category and when it next lands. Bill
  /// or income stays as it was, since confirmed entries were logged as one.
  Future<void> updateRecurring(RecurringItem item);

  /// Removes an item for good. Payments already confirmed stay in History as
  /// ordinary entries, no longer linked to it.
  Future<RecurringRemoval> deleteRecurring(int id);

  /// Undoes [deleteRecurring]: the item comes back with its id, and its
  /// confirmed entries point at it again.
  Future<void> restoreRecurring(RecurringRemoval removal);

  /// Pausing keeps the item and its history but stops it being projected or
  /// offered for confirmation. Items are paused rather than deleted because
  /// confirmed entries refer to them.
  Future<void> setRecurringActive(int id, {required bool active});

  /// Logs the occurrence due on [due] as a real entry dated [paidOn] and
  /// moves the item's next due date forward one month, in one transaction.
  /// Returns the entry logged, or null and does nothing when [due] is no
  /// longer the next one, because it was already paid, or the item is gone
  /// or paused, so a second tap or an old card never pays twice.
  Future<int?> confirmRecurring(int id, {required DateTime due, required DateTime paidOn});


  /// Every event, each with what has been spent against its next
  /// occurrence.
  Stream<List<PlannedEvent>> watchEvents();
  Future<int> addEvent({
    required String name,
    required bool isIncome,
    required int amount,
    required String categoryKey,
    required DateTime date,
    bool countInProjection = true,
    bool repeatsYearly = false,
  });

  /// Marks the occurrence of an event on [date] as having happened. A
  /// one-off one stops being counted; a yearly one moves on to next year's
  /// date, but only from [date], so a second tap never skips a year.
  /// Logging the money itself stays a normal entry.
  Future<void> setEventDone(int id, {required DateTime date, required bool done});

  /// Changes an event's name, amount, category, date, whether it counts and
  /// whether it repeats.
  /// It stays an expense or an income.
  Future<void> updateEvent(PlannedEvent event);

  /// Removes an event. Entries spent on it stay in History, no longer
  /// linked to it.
  Future<EventRemoval> deleteEvent(int id);

  /// Undoes [deleteEvent]: the event comes back with its id, and the
  /// entries spent on it point at it again.
  Future<void> restoreEvent(EventRemoval removal);

  /// Active goals, highest priority first.
  Stream<List<Goal>> watchActiveGoals();

  /// Goals marked bought, most recent first.
  Stream<List<Goal>> watchAchievedGoals();

  /// Sets active goals' priorities to follow [ids], first is highest.
  Future<void> reorderGoals(List<int> ids);
  Future<int> addGoal({required String name, required int price, required DateTime targetDate, int priority = 1, Uri? listingUrl});

  /// Logs the purchase as an expense on [on] and marks the goal achieved, in
  /// one transaction, so it leaves the active goals.
  Future<void> markGoalBought(int id, {required DateTime on});

  /// Changes a goal's name, price, buy day and listing, with what the
  /// listing last showed.
  Future<void> updateGoal(Goal goal);

  /// Records what the goal's listing showed when the user looked on [on].
  Future<void> checkListing(int id, ListingCheck check, {required DateTime on});

  /// Removes a goal, active or bought. A bought goal's purchase stays in
  /// History as the entry it was logged as.
  Future<void> deleteGoal(int id);

  /// Puts back a goal exactly as it was before [deleteGoal], for undo.
  Future<void> restoreGoal(Goal goal);
}
