import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../accounts/presentation/account_providers.dart';
import '../../ledger/presentation/ledger_providers.dart';
import '../../plan/presentation/plan_providers.dart';
import '../../plan/presentation/runway_screen.dart';
import '../data/anthropic_coach_client.dart';
import '../data/drift_coach_chat_repository.dart';
import '../data/drift_coach_settings_repository.dart';
import '../data/secure_coach_key_store.dart';
import '../domain/coach_client.dart';
import '../domain/coach_lookups.dart';
import '../domain/coach_memory.dart';
import '../domain/coach_settings.dart';
import '../domain/week_summary.dart';

final coachClientProvider = Provider<CoachClient>((ref) => AnthropicCoachClient());
final coachKeyStoreProvider = Provider<CoachKeyStore>((ref) => const SecureCoachKeyStore());
final coachChatRepositoryProvider = Provider<CoachChatRepository>((ref) => DriftCoachChatRepository(ref.watch(databaseProvider)));
final coachSettingsRepositoryProvider = Provider<CoachSettingsRepository>((ref) => DriftCoachSettingsRepository(ref.watch(databaseProvider)));

/// The coach's look, personality and memory setting.
final coachSettingsProvider = StreamProvider<CoachSettings>((ref) => ref.watch(coachSettingsRepositoryProvider).watchSettings());

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

/// Everything the coach may look up, as of now. Null until it has loaded.
final coachDataProvider = Provider<CoachData?>((ref) {
  final settings = ref.watch(settingsProvider).value;
  final balance = ref.watch(balanceProvider).value;
  final entries = ref.watch(allEntriesProvider).value;
  final categories = ref.watch(categoriesProvider).value;
  final accounts = ref.watch(accountsProvider).value;
  final rules = ref.watch(rulesProvider).value;
  final recurring = ref.watch(recurringProvider).value;
  if (settings == null || balance == null || entries == null || categories == null || accounts == null || rules == null || recurring == null) {
    return null;
  }
  return CoachData(
    today: ref.watch(todayProvider),
    settings: settings,
    balance: balance,
    entries: entries,
    categories: categories,
    accounts: accounts,
    rules: rules,
    recurring: recurring,
    projection: ref.watch(projectionProvider),
    upcoming: ref.watch(upcomingProvider) ?? const [],
  );
});
