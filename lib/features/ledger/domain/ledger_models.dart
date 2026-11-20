/// Ledger vocabulary: what was spent or received, and how it is grouped.
/// Amounts are positive integer sen; [isIncome] carries the direction.
library;

/// Whose choice a day-to-day spend was: the user's own call, or not their
/// call, when they had no real say in it. Only their own calls count toward
/// the weekly allowance. The names are stored; [label] is what is shown.
enum SpendKind {
  want('My call'),
  need('Not my call');

  const SpendKind(this.label);

  /// The kind as the app and the coach name it to the user.
  final String label;

  /// The kind in running text, such as "not my call".
  String get words => label.toLowerCase();

  /// The kind as the coach's tools name it, such as `not_my_call`.
  String get toolName => words.replaceAll(' ', '_');

  /// The kind the coach named, or null when it named none.
  static SpendKind? fromTool(Object? name) => values.where((k) => k.toolName == name).firstOrNull;
}

class Category {
  const Category({
    required this.key,
    required this.label,
    required this.isIncome,
    required this.tint,
    required this.isFixed,
    this.spendKind = SpendKind.want,
  });

  final String key;
  final String label;
  final bool isIncome;

  /// A design-system tint name; the presentation layer maps it to colours.
  final String tint;

  /// Fixed spending does not count toward the weekly cap.
  final bool isFixed;

  /// The kind a spend here starts as, before the user changes it.
  final SpendKind spendKind;

  /// Goal purchases and check-in gaps are logged by the app, never picked by
  /// hand.
  bool get isAutomatic => key == goalCategoryKey || key == untrackedCategoryKey;
}

/// What an entry was spent on, when it was for a planned event: the event
/// and the date of the occurrence, so a yearly event's years stay apart.
class EventLink {
  const EventLink(this.eventId, this.on);

  final int eventId;
  final DateTime on;

  @override
  bool operator ==(Object other) => other is EventLink && other.eventId == eventId && other.on == on;

  @override
  int get hashCode => Object.hash(eventId, on);
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
    this.receipt,
    this.event,
    this.accountId,
    this.billId,
    this.spendKind = SpendKind.want,
    this.forOthers = 0,
  });

  final int id;
  final DateTime day;
  final bool isIncome;

  /// What counts as the user's own: everything that sums spending reads
  /// this, so a part paid for others never counts as theirs.
  final int amount;
  final String categoryKey;
  final String? label;
  final String? note;

  /// File name of an attached receipt image, if any.
  final String? receipt;

  /// The planned event it was spent on, if any.
  final EventLink? event;

  /// Where the money came from or went to; null means the first account.
  final int? accountId;

  /// The bill or income this pays or receives for its month, if any.
  final int? billId;

  /// Whose choice it was; only a spend's is read.
  final SpendKind spendKind;

  /// Paid for other people on top of [amount], such as their share of a
  /// bill paid in full; owed back until paybacks cover it.
  final int forOthers;

  /// What left the account: the user's own part and the part for others.
  int get paid => amount + forOthers;

  int get signedAmount => isIncome ? amount : -amount;

  /// This entry with a different split, or moved to another account.
  Entry copyWith({int? amount, int? forOthers, int? accountId}) => Entry(
        id: id,
        day: day,
        isIncome: isIncome,
        amount: amount ?? this.amount,
        categoryKey: categoryKey,
        label: label,
        note: note,
        receipt: receipt,
        event: event,
        accountId: accountId ?? this.accountId,
        billId: billId,
        spendKind: spendKind,
        forOthers: forOthers ?? this.forOthers,
      );

  /// Day-to-day spending the plan did not count already: not income, not a
  /// fixed category, and not paid toward a bill or spent on a planned
  /// event, which the plan counts whatever their category.
  bool isFlexible(Set<String> fixedKeys) => !isIncome && !fixedKeys.contains(categoryKey) && billId == null && event == null;

  /// Day-to-day spending that comes out of the weekly allowance.
  bool isWant(Set<String> fixedKeys) => isFlexible(fixedKeys) && spendKind == SpendKind.want;

  /// Day-to-day spending that was bought anyway or asked for, and so is
  /// kept out of the allowance.
  bool isNeed(Set<String> fixedKeys) => isFlexible(fixedKeys) && spendKind == SpendKind.need;
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
    this.receipt,
    this.event,
    this.accountId,
    this.billId,
    this.spendKind = SpendKind.want,
    this.forOthers = 0,
  });

  final DateTime day;
  final bool isIncome;

  /// The user's own part, as on [Entry.amount].
  final int amount;
  final String categoryKey;
  final String? label;
  final String? note;
  final String? receipt;
  final EventLink? event;

  /// Null means the first account.
  final int? accountId;

  /// The bill or income it pays or receives: logging it settles that one's
  /// next month, as Paid does, at the amount actually logged.
  final int? billId;
  final SpendKind spendKind;

  /// Paid for other people on top of [amount], as on [Entry.forOthers].
  final int forOthers;

  /// Whether, once saved, it is day-to-day spending, given whether its
  /// category [isFixed]: the only kind of entry that is a want or a need.
  bool isFlexibleSpend(bool isFixed) => !isIncome && !isFixed && billId == null && event == null;
}

/// Money back from someone the user paid for, toward an entry's
/// [Entry.forOthers]. Like a transfer it is neither income nor spending: it
/// only fills the account it arrived in.
class Payback {
  const Payback({required this.id, required this.entryId, required this.day, required this.amount, this.accountId, this.payer});

  final int id;
  final int entryId;
  final DateTime day;
  final int amount;

  /// Where it arrived; null means the first account.
  final int? accountId;

  /// Who paid it back, as the user wrote it.
  final String? payer;
}

/// A spend partly for others, with what has come back toward their part.
class Owed {
  const Owed(this.entry, this.back);

  final Entry entry;
  final int back;

  /// Still to come back; never below nothing.
  int get left => (entry.forOthers - back).clamp(0, entry.forOthers);
}

/// Every spend with a part for others still owed, oldest first, from
/// [entries] and the [paybacks] toward them.
List<Owed> owedFrom(Iterable<Entry> entries, Iterable<Payback> paybacks) {
  final back = <int, int>{};
  for (final p in paybacks) {
    back[p.entryId] = (back[p.entryId] ?? 0) + p.amount;
  }
  return [
    for (final e in entries.where((e) => e.forOthers > 0)) Owed(e, back[e.id] ?? 0),
  ].where((o) => o.left > 0).toList()
    ..sort((a, b) => a.entry.day.compareTo(b.entry.day) != 0 ? a.entry.day.compareTo(b.entry.day) : a.entry.id.compareTo(b.entry.id));
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
/// What went on wants from [from] to [to], both included: the spending the
/// weekly allowance measures.
int wantsSpent(Iterable<Entry> entries, Set<String> fixedKeys, DateTime from, DateTime to) =>
    _sum(entries.where((e) => e.isWant(fixedKeys) && !e.day.isBefore(from) && !e.day.isAfter(to)));

/// What went on needs from [from] to [to], both included.
int needsSpent(Iterable<Entry> entries, Set<String> fixedKeys, DateTime from, DateTime to) =>
    _sum(entries.where((e) => e.isNeed(fixedKeys) && !e.day.isBefore(from) && !e.day.isAfter(to)));

int _sum(Iterable<Entry> entries) => entries.fold(0, (sum, e) => sum + e.amount);

/// Monday of the week containing [day].
DateTime weekStart(DateTime day) => DateTime.utc(day.year, day.month, day.day - (day.weekday - 1));
