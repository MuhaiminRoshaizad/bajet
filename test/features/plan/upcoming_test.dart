import 'package:bajet/features/plan/domain/plan_models.dart';
import 'package:bajet/features/plan/domain/upcoming.dart';
import 'package:flutter_test/flutter_test.dart';

DateTime d(int y, int m, int day) => DateTime.utc(y, m, day);

void main() {
  test('repeats recurring items monthly and lists everything soonest first', () {
    final list = upcoming(
      recurring: [RecurringItem(id: 1, name: 'Rent', amount: 50000, categoryKey: 'bills', isIncome: false, nextDue: d(2026, 8, 1))],
      events: [PlannedEvent(id: 1, name: 'Car service', amount: 25000, isIncome: false, date: d(2026, 8, 20))],
      goals: [Goal(id: 1, name: 'Laptop', price: 450000, targetDate: d(2026, 9, 15))],
      from: d(2026, 7, 1),
      to: d(2026, 9, 30),
    );
    expect(list.map((i) => (i.name, i.date)), [
      ('Rent', d(2026, 8, 1)),
      ('Car service', d(2026, 8, 20)),
      ('Rent', d(2026, 9, 1)),
      ('Laptop', d(2026, 9, 15)),
    ]);
    expect(list.last.isGoal, isTrue);
    expect(list.first.signedAmount, -50000);
  });

  test('leaves out inactive items, finished events and anything outside the range', () {
    final list = upcoming(
      recurring: [RecurringItem(id: 1, name: 'Old plan', amount: 100, categoryKey: 'bills', isIncome: false, nextDue: d(2026, 7, 5), active: false)],
      events: [
        PlannedEvent(id: 1, name: 'Done', amount: 100, isIncome: false, date: d(2026, 7, 5), done: true),
        PlannedEvent(id: 2, name: 'Too late', amount: 100, isIncome: false, date: d(2026, 12, 1)),
      ],
      goals: const [],
      from: d(2026, 7, 1),
      to: d(2026, 7, 31),
    );
    expect(list, isEmpty);
  });

  test('marks events the projection does not count', () {
    final list = upcoming(
      recurring: const [],
      events: [PlannedEvent(id: 1, name: 'Bonus', amount: 30000, isIncome: true, date: d(2026, 7, 10), countInProjection: false)],
      goals: const [],
      from: d(2026, 7, 1),
      to: d(2026, 7, 31),
    );
    expect((list.single.counted, list.single.signedAmount), (false, 30000));
  });

  test('an item that moves around carries the last day it may land', () {
    final items = upcoming(
      recurring: [RecurringItem(id: 1, name: 'Salary', amount: 300000, categoryKey: 'salary', isIncome: true, nextDue: DateTime.utc(2026, 7, 25), windowDays: 3)],
      events: const [],
      goals: const [],
      from: DateTime.utc(2026, 7, 1),
      to: DateTime.utc(2026, 8, 31),
    );
    expect([for (final i in items) (i.date, i.lastDate)], [
      (DateTime.utc(2026, 7, 25), DateTime.utc(2026, 7, 28)),
      (DateTime.utc(2026, 8, 25), DateTime.utc(2026, 8, 28)),
    ]);
  });
}
