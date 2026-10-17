import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../insights/domain/insights.dart';
import '../../insights/presentation/insights_providers.dart';
import '../../ledger/presentation/ledger_providers.dart';
import '../../plan/presentation/plan_providers.dart';
import '../../plan/presentation/runway_screen.dart';
import '../../report/domain/report.dart';
import '../../report/presentation/report_providers.dart';
import '../data/anthropic_coach_client.dart';
import '../data/secure_coach_key_store.dart';
import '../domain/coach_client.dart';
import '../domain/week_summary.dart';

final coachClientProvider = Provider<CoachClient>((ref) => AnthropicCoachClient());
final coachKeyStoreProvider = Provider<CoachKeyStore>((ref) => const SecureCoachKeyStore());

/// The saved key, or null when there is none.
class CoachKeyController extends AsyncNotifier<String?> {
  @override
  Future<String?> build() => ref.watch(coachKeyStoreProvider).readKey();

  Future<void> save(String key) async {
    await ref.read(coachKeyStoreProvider).saveKey(key);
    ref.invalidateSelf();
  }

  Future<void> remove() async {
    await ref.read(coachKeyStoreProvider).deleteKey();
    ref.invalidateSelf();
  }
}

final coachKeyProvider = AsyncNotifierProvider<CoachKeyController, String?>(CoachKeyController.new);

/// Questions answered today.
final coachUsedTodayProvider = FutureProvider<int>((ref) => ref.watch(coachKeyStoreProvider).usedOn(ref.watch(todayProvider)));

final weekSummaryProvider = Provider<String?>((ref) {
  final balance = ref.watch(balanceProvider).value;
  final settings = ref.watch(settingsProvider).value;
  final entries = ref.watch(recentEntriesProvider).value;
  final categories = ref.watch(categoriesProvider).value;
  final rules = ref.watch(rulesProvider).value;
  if (balance == null || settings == null || entries == null || categories == null || rules == null) return null;
  return weekSummary(
    today: ref.watch(todayProvider),
    balance: balance,
    weeklyCap: settings.weeklyCap,
    buffer: settings.buffer,
    entries: entries,
    categories: categories,
    rules: rules,
    projection: ref.watch(projectionProvider),
    upcoming: ref.watch(upcomingProvider) ?? const [],
  );
});

/// What the coach is told about the owner's money: the week in detail and
/// the month so far. Null until everything has loaded.
final coachContextProvider = Provider<String?>((ref) {
  final week = ref.watch(weekSummaryProvider);
  const thisMonth = (period: InsightsPeriod.month, offset: 0);
  final month = ref.watch(insightsForProvider(thisMonth));
  final accounts = ref.watch(reportAccountsProvider(thisMonth));
  final balance = ref.watch(balanceProvider).value;
  final settings = ref.watch(settingsProvider).value;
  final categories = ref.watch(categoriesProvider).value;
  if (week == null || month == null || accounts == null || balance == null || settings == null || categories == null) return null;
  final monthText = reportText(
    i: month,
    accounts: accounts,
    balance: balance,
    weeklyCap: settings.weeklyCap,
    buffer: settings.buffer,
    categories: {for (final c in categories) c.key: c},
    goal: null,
  );
  return '$week\n\nThis month so far:\n$monthText';
});
