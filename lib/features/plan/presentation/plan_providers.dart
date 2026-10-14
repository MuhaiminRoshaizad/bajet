import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../ledger/domain/ledger_models.dart';
import '../../ledger/presentation/ledger_providers.dart';
import '../data/drift_plan_repository.dart';
import '../domain/plan_models.dart';
import '../domain/plan_repository.dart';
import '../domain/projection.dart';

final planRepositoryProvider = Provider<PlanRepository>((ref) => DriftPlanRepository(ref.watch(databaseProvider)));

final settingsProvider = StreamProvider<PlanSettings?>((ref) => ref.watch(planRepositoryProvider).watchSettings());
final rulesProvider = StreamProvider<List<WeeklyRule>>((ref) => ref.watch(planRepositoryProvider).watchRules());
final recurringProvider = StreamProvider<List<RecurringItem>>((ref) => ref.watch(planRepositoryProvider).watchRecurring());
final eventsProvider = StreamProvider<List<PlannedEvent>>((ref) => ref.watch(planRepositoryProvider).watchEvents());
final goalsProvider = StreamProvider<List<Goal>>((ref) => ref.watch(planRepositoryProvider).watchActiveGoals());
final achievedGoalsProvider = StreamProvider<List<Goal>>((ref) => ref.watch(planRepositoryProvider).watchAchievedGoals());

/// Today's rule from the weekly rhythm, or null while it loads.
final todayRuleProvider = Provider<WeeklyRule?>((ref) {
  final weekday = ref.watch(todayProvider).weekday;
  return ref.watch(rulesProvider).value?.where((r) => r.weekday == weekday).firstOrNull;
});

/// Recurring items due today or overdue, waiting to be confirmed.
final dueRecurringProvider = Provider<List<RecurringItem>>((ref) {
  final today = ref.watch(todayProvider);
  return [...?ref.watch(recurringProvider).value?.where((r) => r.active && !r.nextDue.isAfter(today))];
});

/// Flexible spending logged so far this week (Monday to today).
final weekSpentProvider = Provider<int?>((ref) {
  final today = ref.watch(todayProvider);
  final entries = ref.watch(recentEntriesProvider).value;
  final categories = ref.watch(categoriesProvider).value;
  if (entries == null || categories == null) return null;
  final fixed = {for (final c in categories.where((c) => c.isFixed)) c.key};
  return flexibleSpent(entries, fixed, weekStart(today), today);
});

/// The live projection, or null until setup is done and every input loaded.
final projectionProvider = Provider<Projection?>((ref) {
  final today = ref.watch(todayProvider);
  final balance = ref.watch(balanceProvider).value;
  final settings = ref.watch(settingsProvider).value;
  final rules = ref.watch(rulesProvider).value;
  final recurring = ref.watch(recurringProvider).value;
  final events = ref.watch(eventsProvider).value;
  final goals = ref.watch(goalsProvider).value;
  final entries = ref.watch(recentEntriesProvider).value;
  final categories = ref.watch(categoriesProvider).value;
  if ([balance, settings, rules, recurring, events, goals, entries, categories].contains(null)) return null;

  final fixed = {for (final c in categories!.where((c) => c.isFixed)) c.key};
  return project(
    balance: balance!,
    today: today,
    rules: rules!,
    recurring: recurring!,
    events: events!,
    goals: goals!,
    buffer: settings!.buffer,
    flexSpentToday: flexibleSpent(entries!, fixed, today, today),
  );
});
