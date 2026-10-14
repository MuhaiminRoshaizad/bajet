import 'package:drift/drift.dart';

import 'app_database.dart';

/// Fills a fresh database with a believable, made-up month for screenshots
/// and demos: a workday rhythm, rent and salary, a laptop to save for, and
/// five weeks of small spending ending [today]. Nothing here belongs to
/// anyone; it is only ever written to an in-memory database.
Future<void> fillWithDemoData(AppDatabase db, DateTime today) async {
  DateTime day(int offset) => DateTime.utc(today.year, today.month, today.day + offset);
  final opening = day(-35);
  DateTime nextOn(int dayOfMonth) {
    final thisMonth = DateTime.utc(today.year, today.month, dayOfMonth);
    return thisMonth.isAfter(today) ? thisMonth : DateTime.utc(today.year, today.month + 1, dayOfMonth);
  }

  await db.transaction(() async {
    await db.into(db.appSettings).insert(
          AppSettingsCompanion.insert(openingBalance: 182000, openingDate: opening, weeklyCap: 7000, buffer: 100000),
        );
    for (var w = 1; w <= 7; w++) {
      await db.into(db.weeklyRules).insertOnConflictUpdate(WeeklyRulesCompanion.insert(
            weekday: Value(w),
            label: w <= 5 ? 'Workday' : 'Weekend',
            dayType: w <= 5 ? RhythmDayType.spend : RhythmDayType.flex,
            plannedSpend: const Value(1000),
          ));
    }
    final salary = await db.into(db.recurringItems).insert(RecurringItemsCompanion.insert(
          name: 'Salary',
          kind: EntryKind.income,
          amount: 320000,
          categoryKey: 'salary',
          nextDue: nextOn(25),
        ));
    final rent = await db.into(db.recurringItems).insert(RecurringItemsCompanion.insert(
          name: 'Rent',
          kind: EntryKind.expense,
          amount: 90000,
          categoryKey: 'bills',
          nextDue: nextOn(1),
        ));
    await db.into(db.recurringItems).insert(RecurringItemsCompanion.insert(
          name: 'Phone',
          kind: EntryKind.expense,
          amount: 4800,
          categoryKey: 'bills',
          nextDue: nextOn(10),
        ));
    await db.into(db.plannedEvents).insert(PlannedEventsCompanion.insert(
          name: 'Car service',
          kind: EntryKind.expense,
          amount: 28000,
          categoryKey: 'transport',
          dueOn: day(40),
        ));
    await db.into(db.goals).insert(GoalsCompanion.insert(name: 'Laptop', price: 450000, targetDate: day(120)));
    for (final (i, f) in [('Lunch', 'food', 850), ('Fuel', 'transport', 2000), ('Coffee', 'food', 600)].indexed) {
      await db.into(db.favourites).insert(FavouritesCompanion.insert(label: f.$1, categoryKey: f.$2, amount: f.$3, sortOrder: Value(i)));
    }

    Future<void> log(DateTime on, int amount, String category, String label, {bool income = false, int? recurring}) =>
        db.into(db.entries).insert(EntriesCompanion.insert(
              occurredOn: on,
              kind: income ? EntryKind.income : EntryKind.expense,
              amount: amount,
              categoryKey: category,
              label: Value(label),
              recurringItemId: Value(recurring),
            ));

    // Workday lunches that wander around the plan, fuel each Monday, a
    // weekend treat now and then, and the month's bills and pay.
    const lunches = [850, 920, 780, 1100, 860, 900, 650];
    for (var offset = -34; offset <= 0; offset++) {
      final d = day(offset);
      if (d.weekday <= 5 && offset % 4 != 0) await log(d, lunches[(offset + 34) % lunches.length], 'food', 'Lunch');
      if (d.weekday == DateTime.monday) await log(d, 2000, 'transport', 'Fuel');
      if (d.weekday == DateTime.saturday && offset % 3 == 0) await log(d, 1800, 'gifts', 'Gift');
      if (d.weekday == DateTime.sunday && offset % 2 == 0) await log(d, 1250, 'personal', 'Stationery');
      if (d.day == 1) await log(d, 90000, 'bills', 'Rent', recurring: rent);
      if (d.day == 25) await log(d, 320000, 'salary', 'Salary', income: true, recurring: salary);
    }
  });
}
