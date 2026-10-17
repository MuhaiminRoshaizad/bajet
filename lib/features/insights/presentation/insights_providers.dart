import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../ledger/presentation/ledger_providers.dart';
import '../../plan/presentation/plan_providers.dart';
import '../domain/insights.dart';

/// A week, a month or everything, [offset] weeks or months back from the
/// current one (0 is the current one; "All" has none).
typedef InsightsRange = ({InsightsPeriod period, int offset});

class InsightsPeriodController extends Notifier<InsightsRange> {
  @override
  InsightsRange build() => (period: InsightsPeriod.month, offset: 0);

  void show(InsightsRange range) => state = range;
}

final insightsPeriodProvider = NotifierProvider<InsightsPeriodController, InsightsRange>(InsightsPeriodController.new);

/// The first day Insights can show, or null until it has loaded.
final insightsFirstDayProvider = Provider<DateTime?>((ref) {
  final settings = ref.watch(settingsProvider).value;
  final entries = ref.watch(allEntriesProvider).value;
  if (settings == null || entries == null) return null;
  return firstDay(settings.openingDate, entries);
});

/// The figures for one range, or null until settings, entries and the
/// rhythm have loaded. Insights and the report both read from here.
final insightsForProvider = Provider.family<Insights?, InsightsRange>((ref, range) {
  final settings = ref.watch(settingsProvider).value;
  final entries = ref.watch(allEntriesProvider).value;
  final categories = ref.watch(categoriesProvider).value;
  final rules = ref.watch(rulesProvider).value;
  if (settings == null || entries == null || categories == null || rules == null) return null;
  return insights(
    period: range.period,
    offset: range.offset,
    today: ref.watch(todayProvider),
    openingDate: settings.openingDate,
    weeklyCap: settings.weeklyCap,
    entries: entries,
    categories: categories,
    rules: rules,
  );
});

/// The figures for the period picked on the Insights tab.
final insightsProvider = Provider<Insights?>((ref) => ref.watch(insightsForProvider(ref.watch(insightsPeriodProvider))));
