/// One finished Sunday check-in. Amounts are sen.
class Checkin {
  const Checkin({
    required this.checkedOn,
    required this.balance,
    required this.matched,
    this.untracked = 0,
    this.startingAdjustment = 0,
    required this.allowanceSpent,
    this.leftAfterBuying,
    required this.nextTarget,
  });

  final DateTime checkedOn;

  /// What bajet held across every account.
  final int balance;

  /// Every account was compared with what it really holds and agreed.
  final bool matched;

  /// Money logged as untracked at this check-in.
  final int untracked;

  /// The gap found at the very first check-in, from a starting balance that
  /// was slightly off. Not missed logging, so it is kept apart.
  final int startingAdjustment;

  /// Flexible spending that week, Monday to [checkedOn].
  final int allowanceSpent;

  /// What the first goal leaves after buying; null without a goal.
  final int? leftAfterBuying;

  /// The balance the plan expected on [targetOn].
  final int nextTarget;

  /// The day [nextTarget] is for: a week after [checkedOn].
  DateTime get targetOn => DateTime.utc(checkedOn.year, checkedOn.month, checkedOn.day + 7);
}

/// Where finished check-ins are kept.
abstract interface class CheckinRepository {
  /// Every check-in, newest first.
  Stream<List<Checkin>> watchCheckins();

  /// Saves [checkin], replacing one already finished that day.
  Future<void> save(Checkin checkin);
}
