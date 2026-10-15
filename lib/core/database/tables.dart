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

/// One row only, created during first-run setup.
class AppSettings extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  IntColumn get openingBalance => integer()();
  TextColumn get openingDate => text().map(const DayConverter())();
  IntColumn get weeklyCap => integer()();

  /// The minimum that must remain after buying a goal.
  IntColumn get buffer => integer()();

  @override
  Set<Column> get primaryKey => {id};
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

  /// A short name such as "Coffee", used for per-item stats like average cost.
  TextColumn get label => text().nullable()();
  TextColumn get note => text().nullable()();

  /// File name of an attached receipt image in the app's receipts folder.
  TextColumn get receipt => text().nullable()();

  /// Set when the entry confirms a recurring item.
  IntColumn get recurringItemId => integer().nullable().references(RecurringItems, #id)();
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
