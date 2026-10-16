import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter/widgets.dart';

import 'package:bajet/core/theme/theme_mode.dart';
import 'package:bajet/features/accounts/domain/account_models.dart';
import 'package:bajet/features/accounts/domain/account_repository.dart';
import 'package:bajet/features/accounts/domain/photo_colours.dart';
import 'package:bajet/features/coach/domain/coach_client.dart';
import 'package:bajet/features/launch/data/home_surface.dart';
import 'package:bajet/features/launch/domain/launch_link.dart';
import 'package:bajet/features/lock/domain/app_lock.dart';
import 'package:bajet/features/opening/data/splash_hand_over.dart';
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

/// The ledger, plan and accounts of one test, held in memory.
class FakeWorld implements LedgerRepository, PlanRepository, AccountRepository {
  FakeWorld({PlanSettings? settings, int openingBalance = 150000}) : _settings = _Live(settings) {
    // Set up already: everything in one first account, as after an upgrade.
    if (settings != null) _openFirstAccount(openingBalance);
  }

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
  final lockSettings = FakeLockSettings();

  /// The wall clock the app lock reads; tests move it on to stand for time
  /// spent away.
  DateTime clock = DateTime(2026, 7, 1, 9);
  final deviceAuth = FakeDeviceAuth();
  final recents = FakeRecentsPrivacy();
  final splash = FakeSplash();
  final photos = FakePhotoColours();
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
          final opening = _accountRows.value.fold<int>(0, (sum, a) => sum + a.openingBalance);
          return opening + _entries.value.where((e) => !e.day.isBefore(s.openingDate)).fold<int>(0, (sum, e) => sum + e.signedAmount);
        }

        final subs = [for (final s in [_settings.stream, _entries.stream, _accountRows.stream]) s.listen((_) => c.add(compute()))];
        c.onCancel = () => Future.wait(subs.map((s) => s.cancel()));
      });

  @override
  Future<int> add(EntryDraft d) async {
    final id = _nextId++;
    _entries.value = [
      ..._entries.value,
      Entry(
        id: id,
        day: d.day,
        isIncome: d.isIncome,
        amount: d.amount,
        categoryKey: d.categoryKey,
        label: _blank(d.label),
        note: _blank(d.note),
        receipt: d.receipt,
        event: d.event,
        accountId: d.accountId,
      ),
    ];
    _entriesChanged();
    return id;
  }

  @override
  Future<void> update(Entry e) async {
    _entries.value = [for (final x in _entries.value) x.id == e.id ? e : x];
    _entriesChanged();
  }

  @override
  Future<void> delete(int id) async {
    _entries.value = [..._entries.value.where((e) => e.id != id)];
    _entriesChanged();
  }

  @override
  Future<void> restore(Entry e) async {
    _entries.value = [..._entries.value, e];
    _entriesChanged();
  }

  // Plan

  @override
  Stream<PlanSettings?> watchSettings() => _settings.stream;

  @override
  Future<void> saveSettings(PlanSettings s) async => _settings.value = s;

  // Accounts

  final _accountRows = _Live<List<Account>>([]);
  final _transfers = _Live<List<Transfer>>([]);
  var _nextTransferId = 1;
  final _totalLook = _Live(const TotalCardLook());
  var _nextAccountId = 1;

  TotalCardLook get totalLook => _totalLook.value;

  void _openFirstAccount(int opening) => _accountRows.value = [
        Account(
          id: _nextAccountId++,
          kind: AccountKind.bank,
          name: firstAccountName,
          openingBalance: opening,
          balance: opening,
          look: const CardLook(color: firstAccountColor),
        ),
      ];

  static Account _withOpening(Account a, int opening) =>
      Account(id: a.id, kind: a.kind, name: a.name, nickname: a.nickname, openingBalance: opening, balance: opening, look: a.look);

  List<Account> get accounts {
    final from = _settings.value?.openingDate;
    final firstId = _accountRows.value.firstOrNull?.id;
    bool counted(DateTime day) => from == null || !day.isBefore(from);
    return [
      for (final a in _accountRows.value)
        Account(
          id: a.id,
          kind: a.kind,
          name: a.name,
          nickname: a.nickname,
          openingBalance: a.openingBalance,
          look: a.look,
          balance: a.openingBalance +
              _entries.value.where((e) => (e.accountId ?? firstId) == a.id && counted(e.day)).fold<int>(0, (sum, e) => sum + e.signedAmount) +
              _transfers.value.where((t) => counted(t.day)).fold<int>(0, (sum, t) => sum + (t.toId == a.id ? t.amount : 0) - (t.fromId == a.id ? t.amount : 0)),
        ),
    ];
  }

  @override
  Stream<List<Account>> watchAccounts() => Stream.multi((c) {
        final subs = [
          for (final s in [_accountRows.stream, _entries.stream, _transfers.stream, _settings.stream]) s.listen((_) => c.add(accounts)),
        ];
        c.onCancel = () => Future.wait(subs.map((s) => s.cancel()));
      });

  @override
  Future<int> addAccount(AccountDraft d) async {
    final id = _nextAccountId++;
    _accountRows.value = [
      ..._accountRows.value,
      Account(id: id, kind: d.kind, name: d.name.trim(), nickname: _blank(d.nickname), openingBalance: d.balance, balance: d.balance, look: d.look),
    ];
    return id;
  }

  @override
  Future<void> reorderAccounts(List<int> ids) async =>
      _accountRows.value = [for (final id in ids) _accountRows.value.firstWhere((a) => a.id == id)];

  @override
  Future<void> updateAccount(Account a) async => _accountRows.value = [
        for (final x in _accountRows.value)
          x.id == a.id
              ? Account(id: x.id, kind: x.kind, name: a.name.trim(), nickname: _blank(a.nickname), openingBalance: x.openingBalance, balance: 0, look: a.look)
              : x,
      ];

  @override
  Future<void> setOpeningBalance(int accountId, int balance) async =>
      _accountRows.value = [for (final x in _accountRows.value) x.id == accountId ? _withOpening(x, balance) : x];

  @override
  Future<int> transfer({required int fromId, required int toId, required int amount, required DateTime day, String? note}) async {
    final id = _nextTransferId++;
    _transfers.value = [..._transfers.value, Transfer(id: id, day: day, fromId: fromId, toId: toId, amount: amount, note: _blank(note))];
    return id;
  }

  @override
  Stream<List<Transfer>> watchTransfers() => _transfers.stream.map((all) => [...all]..sort((a, b) {
        final byDay = b.day.compareTo(a.day);
        return byDay != 0 ? byDay : b.id.compareTo(a.id);
      }));

  @override
  Future<void> deleteTransfer(int id) async => _transfers.value = [..._transfers.value.where((t) => t.id != id)];

  int get transferCount => _transfers.value.length;

  @override
  Stream<TotalCardLook> watchTotalLook() => _totalLook.stream;

  @override
  Future<void> saveTotalLook(TotalCardLook look) async => _totalLook.value = look;

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
    int? accountId,
  }) async {
    final id = _nextId++;
    _recurring.value = [..._recurring.value, RecurringItem(id: id, name: name, amount: amount, categoryKey: categoryKey, isIncome: isIncome, nextDue: nextDue, windowDays: windowDays, accountId: accountId)];
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
    await add(EntryDraft(day: paidOn, isIncome: item.isIncome, amount: item.amount, categoryKey: 'bills', label: item.name, accountId: item.accountId));
    final due = item.nextDue;
    _recurring.value = [
      for (final r in _recurring.value)
        r.id == id ? r.copyWith(nextDue: DateTime.utc(due.year, due.month + 1, due.day)) : r,
    ];
  }

  @override
  Stream<List<PlannedEvent>> watchEvents() => _events.stream.map((all) => [for (final e in all) _withSpent(e)]);

  PlannedEvent _withSpent(PlannedEvent e) {
    final link = EventLink(e.id, e.date);
    final spent = _entries.value.where((x) => x.event == link).fold(0, (s, x) => s + x.amount);
    return PlannedEvent(
      id: e.id,
      name: e.name,
      amount: e.amount,
      categoryKey: e.categoryKey,
      isIncome: e.isIncome,
      date: e.date,
      countInProjection: e.countInProjection,
      done: e.done,
      repeatsYearly: e.repeatsYearly,
      spent: spent,
    );
  }

  /// Events show what is spent on them, so they change when entries do.
  void _entriesChanged() => _events.value = _events.value;

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
  Future<EventRemoval> deleteEvent(int id) async {
    final event = _withSpent(_events.value.firstWhere((e) => e.id == id));
    _events.value = [..._events.value.where((e) => e.id != id)];
    return EventRemoval(event, const []);
  }

  @override
  Future<void> restoreEvent(EventRemoval removal) async => _events.value = [..._events.value, removal.event];

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

/// A camera that always sees the same thing: [next] is the photo it takes,
/// by default a wine-red card on a light grey table, the table taking up
/// most of the picture.
class FakePhotoColours implements PhotoColours {
  PhotoSample? next = cardOnTable();

  static PhotoSample cardOnTable({int card = 0xFF7A1F2B, int table = 0xFFE8E8E8}) {
    const w = 40, h = 30;
    final rgba = Uint8List(w * h * 4);
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        // The card fills most of the frame, and no more than a third of the
        // whole photo.
        final c = x >= 6 && x < 34 && y >= 8 && y < 22 ? card : table;
        rgba.setAll((y * w + x) * 4, [c >> 16 & 255, c >> 8 & 255, c & 255, 255]);
      }
    }
    return PhotoSample(width: w, height: h, rgba: rgba);
  }

  @override
  Future<PhotoSample?> pick(PhotoSource source) async => next;
}

/// The home screen without a launcher: records the shortcuts bajet sets, and
/// [launch] stands in for a tap on one.
class FakeHomeSurface implements HomeSurface {
  final _links = StreamController<LaunchLink>.broadcast();
  List<(int, String)>? shortcuts;

  void launch(LaunchLink link) => _links.add(link);

  @override
  Stream<LaunchLink> get launches => _links.stream;

  @override
  Future<void> setShortcuts(List<(int, String)> favourites) async => shortcuts = favourites;
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

class FakeLockSettings implements LockSettingsStore {
  LockSettings saved = const LockSettings();

  @override
  Future<LockSettings> read() async => saved;

  @override
  Future<void> write(LockSettings settings) async => saved = settings;
}

/// The phone's fingerprint prompt: answers with [outcomes] in turn, then
/// keeps giving the last one, and counts how often it was shown.
class FakeDeviceAuth implements DeviceAuth {
  bool available = true;
  List<AuthOutcome> outcomes = [AuthOutcome.passed];
  final titles = <String>[];

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<AuthOutcome> authenticate({required String title, required String reason}) async {
    titles.add(title);
    return outcomes.length > 1 ? outcomes.removeAt(0) : outcomes.single;
  }
}

class FakeRecentsPrivacy implements RecentsPrivacy {
  bool? hidden;

  @override
  Future<void> hideFromRecents(bool hidden) async => this.hidden = hidden;
}

/// Android's splash: [played] says whether Android dealt the cards, as on
/// Android 12 and later.
class FakeSplash implements SplashHandOver {
  bool played = true;
  bool removed = false;

  @override
  Future<bool> ready() async => played;

  @override
  Future<void> remove() async => removed = true;
}
