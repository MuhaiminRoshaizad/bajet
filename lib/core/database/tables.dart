// Column checks such as `amount.isBiggerThanValue(0)` must refer to their own
// getter; drift reads them at build time, so the recursion never runs.
// ignore_for_file: recursive_getters

import 'package:drift/drift.dart';

import '../../features/plan/domain/plan_models.dart' show maxWindowDays;

/// Calendar days are stored as ISO `yyyy-mm-dd` text and read back as UTC
/// midnight, so a day never shifts with the phone's time zone.
class DayConverter extends TypeConverter<DateTime, String> {
  const DayConverter();

  @override
  DateTime fromSql(String fromDb) {
    final p = fromDb.split('-').map(int.parse).toList();
    return DateTime.utc(p[0], p[1], p[2]);
  }

  @override
  String toSql(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
}

enum EntryKind { income, expense }

enum RhythmDayType { zero, spend, flex }

enum GoalStatus { active, paused, achieved, archived }

enum AccountKind { cash, bank, ewallet }

/// How a card is drawn. Leather and suede are the cash wallet's.
enum CardFinish { matte, gloss, mirror, pearl, frosted, guilloche, leather, suede }

/// One row only, created during first-run setup. The starting balance lives
/// on each account, as of [openingDate].
class AppSettings extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  TextColumn get openingDate => text().map(const DayConverter())();
  IntColumn get weeklyCap => integer()();

  /// The minimum that must remain after buying a goal.
  IntColumn get buffer => integer()();

  /// The total card's look; no colour means it follows the app's theme.
  IntColumn get totalCardColor => integer().nullable()();
  TextColumn get totalCardFinish => textEnum<CardFinish>().withDefault(const Constant('matte'))();

  @override
  Set<Column> get primaryKey => {id};
}

/// A place money is kept: cash, a bank account or an e-wallet. Its balance is
/// [openingBalance] on the opening date, plus its entries and transfers since.
class Accounts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get kind => textEnum<AccountKind>()();

  /// The provider, such as a bank's name, shown as plain text; "Cash" for cash.
  TextColumn get name => text()();
  TextColumn get nickname => text().nullable()();
  IntColumn get openingBalance => integer().withDefault(const Constant(0))();

  /// The card's colour as ARGB, and its text colour when the user picked one
  /// (such as gold on black); otherwise text follows the card's lightness.
  IntColumn get color => integer()();
  IntColumn get inkColor => integer().nullable()();
  TextColumn get finish => textEnum<CardFinish>().withDefault(const Constant('matte'))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}

/// Money moved between two accounts. Neither spending nor income, so it lives
/// apart from entries and nothing that sums entries ever sees it.
class Transfers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get occurredOn => text().map(const DayConverter())();
  IntColumn get fromAccountId => integer().references(Accounts, #id)();
  IntColumn get toAccountId => integer().references(Accounts, #id)();
  IntColumn get amount => integer().check(amount.isBiggerThanValue(0))();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<String> get customConstraints => ['CHECK (from_account_id <> to_account_id)'];
}

class Categories extends Table {
  TextColumn get key => text()();
  TextColumn get label => text()();
  TextColumn get kind => textEnum<EntryKind>()();
  TextColumn get tint => text()();

  /// Fixed spending, such as bills, is excluded from the weekly cap.
  BoolColumn get isFixed => boolean().withDefault(const Constant(false))();
  IntColumn get monthlyBudget => integer().nullable()();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {key};
}

class Entries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get occurredOn => text().map(const DayConverter())();
  TextColumn get kind => textEnum<EntryKind>()();
  IntColumn get amount => integer().check(amount.isBiggerThanValue(0))();
  TextColumn get categoryKey => text().references(Categories, #key)();

  /// Where the money came from or went to.
  IntColumn get accountId => integer().references(Accounts, #id)();

  /// A short name such as "Coffee", used for per-item stats like average cost.
  TextColumn get label => text().nullable()();
  TextColumn get note => text().nullable()();

  /// File name of an attached receipt image in the app's receipts folder.
  TextColumn get receipt => text().nullable()();

  /// Set when the entry confirms a recurring item.
  IntColumn get recurringItemId => integer().nullable().references(RecurringItems, #id)();

  /// Set when the entry was spent on a planned event, such as a birthday,
  /// with the date of the occurrence it was for, so a yearly event's
  /// spending stays with its own year.
  IntColumn get plannedEventId => integer().nullable().references(PlannedEvents, #id)();
  TextColumn get plannedEventOn => text().map(const DayConverter()).nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class WeeklyRules extends Table {
  /// 1 is Monday, matching DateTime.weekday.
  IntColumn get weekday => integer().check(weekday.isBetweenValues(1, 7))();
  TextColumn get label => text()();
  TextColumn get dayType => textEnum<RhythmDayType>()();
  IntColumn get plannedSpend => integer().withDefault(const Constant(0))();
  BoolColumn get isFastingDay => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {weekday};
}

class RecurringItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get kind => textEnum<EntryKind>()();
  IntColumn get amount => integer().check(amount.isBiggerThanValue(0))();
  TextColumn get categoryKey => text().references(Categories, #key)();

  /// The next occurrence not yet paid; its day of month repeats monthly.
  TextColumn get nextDue => text().map(const DayConverter())();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
  BoolColumn get isEstimate => boolean().withDefault(const Constant(false))();

  /// Days after [nextDue] it may still land, for pay or bills that move
  /// around; 0 means on the day itself.
  IntColumn get windowDays => integer().withDefault(const Constant(0)).check(windowDays.isBetweenValues(0, maxWindowDays))();

  /// The account it is paid from or into.
  IntColumn get accountId => integer().references(Accounts, #id)();
}

class PlannedEvents extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get kind => textEnum<EntryKind>()();
  IntColumn get amount => integer().check(amount.isBiggerThanValue(0))();
  TextColumn get categoryKey => text().references(Categories, #key)();
  TextColumn get dueOn => text().map(const DayConverter())();
  BoolColumn get done => boolean().withDefault(const Constant(false))();

  /// False for money that may not arrive, such as an unconfirmed bonus.
  BoolColumn get countInProjection => boolean().withDefault(const Constant(true))();

  /// Comes back on the same date every year, such as a birthday; [dueOn] is
  /// the next one, and marking it done moves it on a year.
  BoolColumn get repeatsYearly => boolean().withDefault(const Constant(false))();
}

class Goals extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  IntColumn get price => integer().check(price.isBiggerThanValue(0))();
  TextColumn get targetDate => text().map(const DayConverter())();
  IntColumn get priority => integer().withDefault(const Constant(1))();
  TextColumn get listingUrl => text().nullable()();
  TextColumn get status => textEnum<GoalStatus>().withDefault(const Constant('active'))();
  TextColumn get achievedOn => text().map(const DayConverter()).nullable()();
}

/// Shortcuts that fill in the logger. They never log on their own.
class Favourites extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get label => text()();
  TextColumn get categoryKey => text().references(Categories, #key)();
  IntColumn get amount => integer().check(amount.isBiggerThanValue(0))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}

/// How the coach looks and talks, and whether it remembers. One row, written
/// the first time the user changes any of it; until then the defaults hold.
class CoachSettings extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();

  /// Which avatar draws the coach, by its key, such as "bajety".
  TextColumn get face => text().withDefault(const Constant('bajety'))();

  /// Which personality it talks in, by its key, such as "friendly".
  TextColumn get personality => text().withDefault(const Constant('friendly'))();
  BoolColumn get remember => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

/// One chat with the coach, as listed on the Coach tab: its name, whether it
/// is pinned, and who coaches it in which voice. Like its messages it stays
/// on the phone (decision 024).
class CoachThreads extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Named after its first question unless the user renames it.
  TextColumn get title => text()();
  BoolColumn get pinned => boolean().withDefault(const Constant(false))();

  /// The avatar and the personality this chat uses, by their keys.
  TextColumn get face => text()();
  TextColumn get personality => text()();

  /// When it was started, in milliseconds since the epoch.
  IntColumn get createdAt => integer()();
}

/// The remembered messages, oldest first, each in its chat. They stay on
/// the phone: a backup file never carries them (decision 024).
class CoachMessages extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get threadId => integer().references(CoachThreads, #id, onDelete: KeyAction.cascade)();

  /// When it was sent, in milliseconds since the epoch, for the day labels
  /// and for spotting a question sent twice in a row.
  IntColumn get sentAt => integer()();
  BoolColumn get fromUser => boolean()();
  TextColumn get body => text()();

  /// The avatar that said it, so a reply keeps its face after a switch.
  TextColumn get face => text().nullable()();

  /// What the coach looked up for a reply, one label a line.
  TextColumn get looked => text().withDefault(const Constant(''))();

  /// The reply's suggestion cards and what became of them, as JSON.
  TextColumn get cards => text().withDefault(const Constant(''))();

  /// A line in the chat said by nobody, such as a change of personality.
  BoolColumn get note => boolean().withDefault(const Constant(false))();
}

/// One finished Sunday check-in, one a day: finishing again the same day
/// replaces it. It keeps what the week's report compares against later,
/// above all [nextTarget], the balance the plan expects a week on.
class Checkins extends Table {
  TextColumn get checkedOn => text().map(const DayConverter())();

  /// What bajet held across every account when the check-in was finished.
  IntColumn get balance => integer()();

  /// Every account was compared with what it really holds and agreed.
  BoolColumn get matched => boolean()();

  /// Money logged as untracked at this check-in.
  IntColumn get untracked => integer().withDefault(const Constant(0))();

  /// The gap found at the very first check-in, from a starting balance that
  /// was slightly off. It is not missed logging, so it is kept apart.
  IntColumn get startingAdjustment => integer().withDefault(const Constant(0))();

  /// Flexible spending that week, Monday to the check-in.
  IntColumn get allowanceSpent => integer()();

  /// What the first goal leaves after buying; null without a goal.
  IntColumn get leftAfterBuying => integer().nullable()();

  /// The balance the plan expected seven days after [checkedOn].
  IntColumn get nextTarget => integer()();

  @override
  Set<Column> get primaryKey => {checkedOn};
}
