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
  return wantsSpent(entries, fixed, weekStart(today), today);
});

/// The live projection of the plan as saved, or null until setup is done and
/// every input loaded.
final projectionProvider = Provider<Projection?>((ref) => ref.watch(projectionWithProvider(WhatIf.none)));

/// The what-if being tried on Runway. Never saved; the plan is untouched.
class WhatIfController extends Notifier<WhatIf> {
  @override
  WhatIf build() => WhatIf.none;

  void change(WhatIf next) => state = next;

  void reset() => state = WhatIf.none;
}

final whatIfProvider = NotifierProvider<WhatIfController, WhatIf>(WhatIfController.new);

/// The projection with a what-if applied.
final projectionWithProvider = Provider.family<Projection?, WhatIf>((ref, whatIf) => _project(ref, whatIf: whatIf));

/// The projection as saved, run at least through [day], even past the last
/// goal, for a balance the plan expects on that day.
final projectionThroughProvider = Provider.family<Projection?, DateTime>((ref, day) => _project(ref, through: day));

Projection? _project(Ref ref, {WhatIf whatIf = WhatIf.none, DateTime? through}) {
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
    flexSpentToday: wantsSpent(entries!, fixed, today, today),
    through: through,
    whatIf: whatIf,
  );
}
