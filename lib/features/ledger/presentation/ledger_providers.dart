import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../data/drift_ledger_repository.dart';
import '../domain/ledger_models.dart';
import '../domain/ledger_repository.dart';

final ledgerRepositoryProvider = Provider<LedgerRepository>((ref) => DriftLedgerRepository(ref.watch(databaseProvider)));

final favouriteRepositoryProvider = Provider<FavouriteRepository>((ref) => DriftFavouriteRepository(ref.watch(databaseProvider)));

final categoriesProvider = StreamProvider<List<Category>>((ref) => ref.watch(ledgerRepositoryProvider).watchCategories());

final favouritesProvider = StreamProvider<List<Favourite>>((ref) => ref.watch(favouriteRepositoryProvider).watchAll());

/// Null until first-run setup has stored an opening balance.
final balanceProvider = StreamProvider<int?>((ref) => ref.watch(ledgerRepositoryProvider).watchBalance());

/// Entries from the last 60 days, newest first; enough for Today, the
/// weekly ring and recent history without loading the whole ledger.
final recentEntriesProvider = StreamProvider<List<Entry>>((ref) {
  final today = ref.watch(todayProvider);
  return ref.watch(ledgerRepositoryProvider).watchSince(DateTime.utc(today.year, today.month, today.day - 60));
});
