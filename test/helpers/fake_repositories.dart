import 'dart:async';

import 'package:bajet/features/ledger/domain/ledger_models.dart';
import 'package:bajet/features/ledger/domain/ledger_repository.dart';
import 'package:bajet/features/plan/domain/plan_models.dart';
import 'package:bajet/features/plan/domain/plan_repository.dart';

/// Holds a value and replays the latest one to every new listener, like a
/// database query stream.
class _Live<T> {
  _Live(this._value);

  T _value;
  final _listeners = <MultiStreamController<T>>{};

  T get value => _value;

  set value(T next) {
    _value = next;
    for (final l in _listeners) {
      l.add(next);
    }
  }

  Stream<T> get stream => Stream.multi((c) {
        c.add(_value);
        _listeners.add(c);
        c.onCancel = () => _listeners.remove(c);
      });
}

const demoCategories = [
  Category(key: 'food', label: 'Food', isIncome: false, tint: 'apricot', isFixed: false),
  Category(key: 'transport', label: 'Transport', isIncome: false, tint: 'sky', isFixed: false),
  Category(key: 'pets', label: 'Pets', isIncome: false, tint: 'sage', isFixed: false),
  Category(key: 'family', label: 'Family', isIncome: false, tint: 'rose', isFixed: false),
  Category(key: 'gifts', label: 'Gifts', isIncome: false, tint: 'pink', isFixed: false),
  Category(key: 'bills', label: 'Bills', isIncome: false, tint: 'teal', isFixed: true),
  Category(key: 'personal', label: 'Personal', isIncome: false, tint: 'olive', isFixed: false),
  Category(key: 'other', label: 'Other', isIncome: false, tint: 'neutral', isFixed: false),
  Category(key: 'salary', label: 'Salary', isIncome: true, tint: 'sage', isFixed: true),
  Category(key: 'refund', label: 'Refund', isIncome: true, tint: 'sky', isFixed: false),
];

/// The ledger and plan of one test, held in memory.
class FakeWorld implements LedgerRepository, PlanRepository {
  FakeWorld({PlanSettings? settings}) : _settings = _Live(settings);

  final _Live<PlanSettings?> _settings;
  final _entries = _Live<List<Entry>>([]);
  final _rules = _Live<List<WeeklyRule>>([
    for (var w = 1; w <= 7; w++) WeeklyRule(weekday: w, label: w <= 5 ? 'Weekday' : 'Weekend', type: DayType.spend, plannedSpend: 0),
  ]);
  final _recurring = _Live<List<RecurringItem>>([]);
  final _events = _Live<List<PlannedEvent>>([]);
  final _goals = _Live<List<Goal>>([]);
  final favourites = FakeFavourites();
  var _nextId = 1;

  PlanSettings? get settings => _settings.value;
  List<Entry> get entries => _entries.value;
  List<Goal> get goals => _goals.value;
  List<RecurringItem> get recurring => _recurring.value;

  // Ledger

  @override
  Stream<List<Category>> watchCategories() => Stream.value(demoCategories);

  @override
  Stream<List<Entry>> watchSince(DateTime from) =>
      _entries.stream.map((all) => [...all.where((e) => !e.day.isBefore(from))]..sort((a, b) => b.day.compareTo(a.day) != 0 ? b.day.compareTo(a.day) : b.id.compareTo(a.id)));

  @override
  Stream<int?> watchBalance() => Stream.multi((c) {
        int? compute() {
          final s = _settings.value;
          if (s == null) return null;
          return s.openingBalance + _entries.value.where((e) => !e.day.isBefore(s.openingDate)).fold<int>(0, (sum, e) => sum + e.signedAmount);
        }

        final subs = [_settings.stream.listen((_) => c.add(compute())), _entries.stream.listen((_) => c.add(compute()))];
        c.onCancel = () => Future.wait(subs.map((s) => s.cancel()));
      });

  @override
  Future<int> add(EntryDraft d) async {
    final id = _nextId++;
    _entries.value = [
      ..._entries.value,
      Entry(id: id, day: d.day, isIncome: d.isIncome, amount: d.amount, categoryKey: d.categoryKey, label: _blank(d.label), note: _blank(d.note)),
    ];
    return id;
  }

  @override
  Future<void> update(Entry e) async => _entries.value = [for (final x in _entries.value) x.id == e.id ? e : x];

  @override
  Future<void> delete(int id) async => _entries.value = [..._entries.value.where((e) => e.id != id)];

  @override
  Future<void> restore(Entry e) async => _entries.value = [..._entries.value, e];

  // Plan

  @override
  Stream<PlanSettings?> watchSettings() => _settings.stream;

  @override
  Future<void> saveSettings(PlanSettings s) async => _settings.value = s;

  @override
  Stream<List<WeeklyRule>> watchRules() => _rules.stream;

  @override
  Future<void> saveRule(WeeklyRule rule) async => _rules.value = [for (final r in _rules.value) r.weekday == rule.weekday ? rule : r];

  @override
  Stream<List<RecurringItem>> watchRecurring() => _recurring.stream;

  @override
  Future<int> addRecurring({required String name, required bool isIncome, required int amount, required String categoryKey, required DateTime nextDue}) async {
    final id = _nextId++;
    _recurring.value = [..._recurring.value, RecurringItem(id: id, name: name, amount: amount, isIncome: isIncome, nextDue: nextDue)];
    return id;
  }

  @override
  Future<void> setRecurringActive(int id, {required bool active}) async => _recurring.value = [
        for (final r in _recurring.value)
          r.id == id ? RecurringItem(id: r.id, name: r.name, amount: r.amount, isIncome: r.isIncome, nextDue: r.nextDue, active: active) : r,
      ];

  @override
  Future<void> confirmRecurring(int id, {required DateTime paidOn}) async {
    final item = _recurring.value.firstWhere((r) => r.id == id);
    await add(EntryDraft(day: paidOn, isIncome: item.isIncome, amount: item.amount, categoryKey: 'bills', label: item.name));
    final due = item.nextDue;
    _recurring.value = [
      for (final r in _recurring.value)
        r.id == id
            ? RecurringItem(id: r.id, name: r.name, amount: r.amount, isIncome: r.isIncome, nextDue: DateTime.utc(due.year, due.month + 1, due.day))
            : r,
    ];
  }

  @override
  Stream<List<PlannedEvent>> watchEvents() => _events.stream;

  @override
  Stream<List<Goal>> watchActiveGoals() => _goals.stream;

  @override
  Future<int> addGoal({required String name, required int price, required DateTime targetDate, int priority = 1}) async {
    final id = _nextId++;
    _goals.value = [..._goals.value, Goal(id: id, name: name.trim(), price: price, targetDate: targetDate, priority: priority)];
    return id;
  }
}

class FakeFavourites implements FavouriteRepository {
  final _all = _Live<List<Favourite>>([]);
  var _nextId = 1;

  List<Favourite> get all => _all.value;

  @override
  Stream<List<Favourite>> watchAll() => _all.stream;

  @override
  Future<int> add({required String label, required String categoryKey, required int amount}) async {
    final id = _nextId++;
    _all.value = [..._all.value, Favourite(id: id, label: label.trim(), categoryKey: categoryKey, amount: amount)];
    return id;
  }

  @override
  Future<void> update(Favourite f) async => _all.value = [for (final x in _all.value) x.id == f.id ? f : x];

  @override
  Future<void> delete(int id) async => _all.value = [..._all.value.where((f) => f.id != id)];
}

String? _blank(String? s) => (s == null || s.trim().isEmpty) ? null : s.trim();
