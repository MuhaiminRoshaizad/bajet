import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../data/device_receipt_store.dart';
import '../data/drift_ledger_repository.dart';
import '../domain/ledger_models.dart';
import '../domain/ledger_repository.dart';
import '../domain/receipt_store.dart';

final ledgerRepositoryProvider = Provider<LedgerRepository>((ref) => DriftLedgerRepository(ref.watch(databaseProvider)));

final favouriteRepositoryProvider = Provider<FavouriteRepository>((ref) => DriftFavouriteRepository(ref.watch(databaseProvider)));

final categoriesProvider = StreamProvider<List<Category>>((ref) => ref.watch(ledgerRepositoryProvider).watchCategories());

final favouritesProvider = StreamProvider<List<Favourite>>((ref) => ref.watch(favouriteRepositoryProvider).watchAll());

/// Null until first-run setup has stored an opening balance.
final balanceProvider = StreamProvider<int?>((ref) => ref.watch(ledgerRepositoryProvider).watchBalance());

/// Every entry, newest first, for History and Insights.
final allEntriesProvider = StreamProvider<List<Entry>>((ref) => ref.watch(ledgerRepositoryProvider).watchSince(DateTime.utc(2000)));

/// Entries from the last 60 days, newest first; enough for Today, the
/// weekly ring and recent history without loading the whole ledger.
final recentEntriesProvider = StreamProvider<List<Entry>>((ref) {
  final today = ref.watch(todayProvider);
  return ref.watch(ledgerRepositoryProvider).watchSince(DateTime.utc(today.year, today.month, today.day - 60));
});

final receiptStoreProvider = Provider<ReceiptStore>((ref) => DeviceReceiptStore());

/// Clears out receipt images no entry refers to. Watched once when the app
/// starts, before any log is being written, so an unsaved log's image or a
/// deleted entry's image (whose undo has long expired) never lingers.
final receiptCleanupProvider = FutureProvider<void>((ref) async {
  // A one-off read: watching the entries would run this again on every log.
  final entries = await ref.read(ledgerRepositoryProvider).watchSince(DateTime.utc(2000)).first;
  await ref.read(receiptStoreProvider).keepOnly({for (final e in entries) ?e.receipt});
});
