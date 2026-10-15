import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter/widgets.dart';

import 'package:bajet/core/theme/theme_mode.dart';
import 'package:bajet/features/coach/domain/coach_client.dart';
import 'package:bajet/features/launch/data/home_surface.dart';
import 'package:bajet/features/launch/domain/launch_link.dart';
import 'package:bajet/features/ledger/domain/ledger_models.dart';
import 'package:bajet/features/ledger/domain/ledger_repository.dart';
import 'package:bajet/features/ledger/domain/receipt_store.dart';
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
  Category(key: goalCategoryKey, label: 'Goals', isIncome: false, tint: 'apricot', isFixed: true),
  Category(key: untrackedCategoryKey, label: 'Untracked', isIncome: false, tint: 'neutral', isFixed: true),
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
  final _achieved = _Live<List<Goal>>([]);
  final favourites = FakeFavourites();
  final receipts = FakeReceipts();
  final home = FakeHomeSurface();
  final coachKeys = FakeCoachKeys();
  final coach = FakeCoach();
  final themeModes = FakeThemeModes();
  var _nextId = 1;

  PlanSettings? get settings => _settings.value;
  List<Entry> get entries => _entries.value;
  List<Goal> get goals => _goals.value;
  List<RecurringItem> get recurring => _recurring.value;
  List<PlannedEvent> get events => _events.value;

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
      Entry(id: id, day: d.day, isIncome: d.isIncome, amount: d.amount, categoryKey: d.categoryKey, label: _blank(d.label), note: _blank(d.note), receipt: d.receipt),
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
  Future<int> addRecurring({
    required String name,
    required bool isIncome,
    required int amount,
    required String categoryKey,
    required DateTime nextDue,
    int windowDays = 0,
  }) async {
    final id = _nextId++;
    _recurring.value = [..._recurring.value, RecurringItem(id: id, name: name, amount: amount, categoryKey: categoryKey, isIncome: isIncome, nextDue: nextDue, windowDays: windowDays)];
    return id;
  }

  @override
  Future<RecurringRemoval> deleteRecurring(int id) async {
    final item = _recurring.value.firstWhere((r) => r.id == id);
    _recurring.value = [..._recurring.value.where((r) => r.id != id)];
    return RecurringRemoval(item, const []);
  }

  @override
  Future<void> restoreRecurring(RecurringRemoval removal) async => _recurring.value = [..._recurring.value, removal.item];

  @override
  Future<void> updateRecurring(RecurringItem item) async => _recurring.value = [for (final r in _recurring.value) r.id == item.id ? item : r];

  @override
  Future<void> setRecurringActive(int id, {required bool active}) async => _recurring.value = [
        for (final r in _recurring.value)
          r.id == id ? r.copyWith(active: active) : r,
      ];

  @override
  Future<void> confirmRecurring(int id, {required DateTime paidOn}) async {
    final item = _recurring.value.firstWhere((r) => r.id == id);
    await add(EntryDraft(day: paidOn, isIncome: item.isIncome, amount: item.amount, categoryKey: 'bills', label: item.name));
    final due = item.nextDue;
    _recurring.value = [
      for (final r in _recurring.value)
        r.id == id ? r.copyWith(nextDue: DateTime.utc(due.year, due.month + 1, due.day)) : r,
    ];
  }

  @override
  Stream<List<PlannedEvent>> watchEvents() => _events.stream;

  @override
  Future<int> addEvent({
    required String name,
    required bool isIncome,
    required int amount,
    required String categoryKey,
    required DateTime date,
    bool countInProjection = true,
    bool repeatsYearly = false,
  }) async {
    final id = _nextId++;
    _events.value = [
      ..._events.value,
      PlannedEvent(
        id: id,
        name: name.trim(),
        amount: amount,
        categoryKey: categoryKey,
        isIncome: isIncome,
        date: date,
        countInProjection: countInProjection,
        repeatsYearly: repeatsYearly,
      ),
    ];
    return id;
  }

  @override
  Future<void> setEventDone(int id, {required bool done}) async => _events.value = [
        for (final e in _events.value)
          e.id == id
              ? done && e.repeatsYearly
                  ? e.copyWith(date: DateTime.utc(e.date.year + 1, e.date.month, e.date.day))
                  : e.copyWith(done: done)
              : e,
      ];

  @override
  Future<void> markGoalBought(int id, {required DateTime on}) async {
    final goal = _goals.value.firstWhere((g) => g.id == id);
    await add(EntryDraft(day: on, isIncome: false, amount: goal.price, categoryKey: goalCategoryKey, label: goal.name));
    _goals.value = [..._goals.value.where((g) => g.id != id)];
    _achieved.value = [
      Goal(id: goal.id, name: goal.name, price: goal.price, targetDate: goal.targetDate, priority: goal.priority, achievedOn: on),
      ..._achieved.value,
    ];
  }

  @override
  Future<void> updateEvent(PlannedEvent event) async => _events.value = [for (final e in _events.value) e.id == event.id ? event : e];

  @override
  Future<void> deleteEvent(int id) async => _events.value = [..._events.value.where((e) => e.id != id)];

  @override
  Future<void> restoreEvent(PlannedEvent event) async => _events.value = [..._events.value, event];

  @override
  Stream<List<Goal>> watchAchievedGoals() => _achieved.stream;

  List<Goal> get achieved => _achieved.value;

  @override
  Future<void> updateGoal(Goal goal) async => _goals.value = [for (final g in _goals.value) g.id == goal.id ? goal : g];

  @override
  Future<void> deleteGoal(int id) async {
    _goals.value = [..._goals.value.where((g) => g.id != id)];
    _achieved.value = [..._achieved.value.where((g) => g.id != id)];
  }

  @override
  Future<void> restoreGoal(Goal goal) async {
    if (goal.achievedOn == null) {
      _goals.value = [..._goals.value, goal];
    } else {
      _achieved.value = [..._achieved.value, goal];
    }
  }

  @override
  Future<void> reorderGoals(List<int> ids) async => _goals.value = [
        for (final (i, id) in ids.indexed)
          () {
            final g = _goals.value.firstWhere((g) => g.id == id);
            return Goal(id: g.id, name: g.name, price: g.price, targetDate: g.targetDate, priority: i + 1);
          }(),
      ];

  @override
  Stream<List<Goal>> watchActiveGoals() => _goals.stream.map((all) => [...all]..sort((a, b) => a.priority.compareTo(b.priority)));

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

/// Receipts without a camera or a disk: [next] is what the next pick returns.
class FakeReceipts implements ReceiptStore {
  String? next = 'receipt-1.jpg';
  Set<String>? kept;

  // The smallest valid GIF, so an Image can decode it.
  static final _pixel = Uint8List.fromList([
    0x47, 0x49, 0x46, 0x38, 0x39, 0x61, 1, 0, 1, 0, 0x80, 0, 0, 0, 0, 0, 0xff, 0xff, 0xff, //
    0x21, 0xf9, 4, 1, 0, 0, 0, 0, 0x2c, 0, 0, 0, 0, 1, 0, 1, 0, 0, 2, 2, 0x44, 1, 0, 0x3b,
  ]);

  @override
  Future<String?> pick(ReceiptSource source) async => next;

  @override
  Future<ImageProvider> image(String name) async => MemoryImage(_pixel);

  @override
  Future<void> keepOnly(Set<String> names) async => kept = names;
}

/// The home screen without a launcher: records what bajet sends it, and
/// [launch] stands in for a tap on a shortcut or the widget.
class FakeHomeSurface implements HomeSurface {
  final _links = StreamController<LaunchLink>.broadcast();
  List<(int, String)>? shortcuts;
  WidgetSnapshot? widget;

  void launch(LaunchLink link) => _links.add(link);

  @override
  Stream<LaunchLink> get launches => _links.stream;

  @override
  Future<void> setShortcuts(List<(int, String)> favourites) async => shortcuts = favourites;

  @override
  Future<void> updateWidget(WidgetSnapshot snapshot) async => widget = snapshot;
}

class FakeCoachKeys implements CoachKeyStore {
  String? key;
  final used = <DateTime, int>{};

  @override
  Future<String?> readKey() async => key;

  @override
  Future<void> saveKey(String k) async => key = k.trim();

  @override
  Future<void> deleteKey() async => key = null;

  @override
  Future<int> usedOn(DateTime day) async => used[day] ?? 0;

  @override
  Future<void> recordUse(DateTime day) async => used[day] = (used[day] ?? 0) + 1;
}

/// Answers with [reply], or throws [failWith]; records what it was sent.
class FakeCoach implements CoachClient {
  String reply = 'You are on track.';
  CoachProblem? failWith;
  String? lastSystem;
  List<CoachMessage>? lastConversation;

  @override
  Future<String> ask({required String apiKey, required String system, required List<CoachMessage> conversation}) async {
    lastSystem = system;
    lastConversation = conversation;
    if (failWith != null) throw CoachException(failWith!);
    return reply;
  }
}

class FakeThemeModes implements ThemeModeStore {
  ThemeMode saved = ThemeMode.system;

  @override
  Future<ThemeMode> read() async => saved;

  @override
  Future<void> write(ThemeMode mode) async => saved = mode;
}
