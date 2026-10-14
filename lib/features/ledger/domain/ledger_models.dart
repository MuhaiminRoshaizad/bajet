/// Ledger vocabulary: what was spent or received, and how it is grouped.
/// Amounts are positive integer sen; [isIncome] carries the direction.
library;

class Category {
  const Category({
    required this.key,
    required this.label,
    required this.isIncome,
    required this.tint,
    required this.isFixed,
  });

  final String key;
  final String label;
  final bool isIncome;

  /// A design-system tint name; the presentation layer maps it to colours.
  final String tint;

  /// Fixed spending does not count toward the weekly cap.
  final bool isFixed;

  /// Goal purchases and check-in gaps are logged by the app, never picked by
  /// hand.
  bool get isAutomatic => key == goalCategoryKey || key == untrackedCategoryKey;
}

class Entry {
  const Entry({
    required this.id,
    required this.day,
    required this.isIncome,
    required this.amount,
    required this.categoryKey,
    this.label,
    this.note,
  });

  final int id;
  final DateTime day;
  final bool isIncome;
  final int amount;
  final String categoryKey;
  final String? label;
  final String? note;

  int get signedAmount => isIncome ? amount : -amount;
}

/// An entry not yet saved, as the logger builds it.
class EntryDraft {
  const EntryDraft({
    required this.day,
    required this.isIncome,
    required this.amount,
    required this.categoryKey,
    this.label,
    this.note,
  });

  final DateTime day;
  final bool isIncome;
  final int amount;
  final String categoryKey;
  final String? label;
  final String? note;
}

class Favourite {
  const Favourite({required this.id, required this.label, required this.categoryKey, required this.amount});

  final int id;
  final String label;
  final String categoryKey;
  final int amount;
}

/// The category goal purchases are logged under. It is fixed, so a purchase
/// never counts toward the weekly cap, and the logger does not offer it.
const goalCategoryKey = 'goal';

/// Money that left the account without being logged, found by comparing
/// with the bank at a check-in. Fixed, so a lump found on Sunday does not
/// mark the week over its allowance.
const untrackedCategoryKey = 'untracked';

/// Spending that counts toward the weekly cap: expenses outside fixed
/// categories, from [from] to [to] inclusive.
int flexibleSpent(Iterable<Entry> entries, Set<String> fixedKeys, DateTime from, DateTime to) => entries
    .where((e) => !e.isIncome && !fixedKeys.contains(e.categoryKey) && !e.day.isBefore(from) && !e.day.isAfter(to))
    .fold(0, (sum, e) => sum + e.amount);

/// Monday of the week containing [day].
DateTime weekStart(DateTime day) => DateTime.utc(day.year, day.month, day.day - (day.weekday - 1));
