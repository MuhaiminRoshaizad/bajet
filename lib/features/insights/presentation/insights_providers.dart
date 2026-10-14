import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../ledger/presentation/ledger_providers.dart';
import '../../plan/presentation/plan_providers.dart';
import '../domain/insights.dart';

class InsightsPeriodController extends Notifier<InsightsPeriod> {
  @override
  InsightsPeriod build() => InsightsPeriod.month;

  void select(InsightsPeriod period) => state = period;
}

final insightsPeriodProvider = NotifierProvider<InsightsPeriodController, InsightsPeriod>(InsightsPeriodController.new);

/// The figures for one period, or null until settings, entries and the
/// rhythm have loaded. Insights and the report both read from here.
final insightsForProvider = Provider.family<Insights?, InsightsPeriod>((ref, period) {
  final settings = ref.watch(settingsProvider).value;
  final entries = ref.watch(allEntriesProvider).value;
  final categories = ref.watch(categoriesProvider).value;
  final rules = ref.watch(rulesProvider).value;
  if (settings == null || entries == null || categories == null || rules == null) return null;
  return insights(
    period: period,
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
