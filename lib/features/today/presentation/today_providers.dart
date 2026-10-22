import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../../core/dates/dates.dart';
import '../../ledger/domain/ledger_models.dart';
import '../../ledger/presentation/ledger_providers.dart';
import '../../plan/presentation/plan_providers.dart';
import 'week_dial.dart';

/// Monday to Sunday of the current week, each with its flexible spend and
/// what the rhythm planned. Null while inputs load.
final weekDaysProvider = Provider<List<WeekDay>?>((ref) {
  final today = ref.watch(todayProvider);
  final rules = ref.watch(rulesProvider).value;
  final entries = ref.watch(recentEntriesProvider).value;
  final categories = ref.watch(categoriesProvider).value;
  if (rules == null || entries == null || categories == null) return null;

  final fixed = {for (final c in categories.where((c) => c.isFixed)) c.key};
  final monday = weekStart(today);
  return [
    for (var i = 0; i < 7; i++)
      () {
        final day = DateTime.utc(monday.year, monday.month, monday.day + i);
        final spent = wantsSpent(entries, fixed, day, day);
        final planned = rules.where((r) => r.weekday == day.weekday).firstOrNull?.plannedSpend ?? 0;
        return WeekDay(date: day, label: Dates.weekday(day), spent: spent, planned: planned);
      }(),
  ];
});
