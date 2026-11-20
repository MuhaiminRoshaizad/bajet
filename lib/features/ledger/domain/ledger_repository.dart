import 'ledger_models.dart';

/// Storage-agnostic access to entries and categories. The drift
/// implementation is the only one today; a synced one could replace it.
abstract interface class LedgerRepository {
  Stream<List<Category>> watchCategories();

  /// Entries from [from] onward, newest first.
  Stream<List<Entry>> watchSince(DateTime from);

  /// Opening balance plus every entry from the opening date, or null before
  /// first-run setup has stored an opening balance.
  Stream<int?> watchBalance();

  Future<int> add(EntryDraft draft);
  Future<void> update(Entry entry);

  /// Removes the entry, and any paybacks toward it, which are returned so
  /// [restore] can put them back.
  Future<List<Payback>> delete(int id);

  /// Puts back an entry removed by [delete], keeping its id, with the
  /// [paybacks] that went with it, for undo.
  Future<void> restore(Entry entry, {List<Payback> paybacks = const []});

  /// Every payback, newest first.
  Stream<List<Payback>> watchPaybacks();

  /// Records money back toward [entryId]'s part for others.
  Future<int> addPayback({required int entryId, required DateTime day, required int amount, int? accountId, String? payer});
  Future<void> deletePayback(int id);

  /// Puts back a payback removed by [deletePayback], keeping its id.
  Future<void> restorePayback(Payback payback);
}

abstract interface class FavouriteRepository {
  Stream<List<Favourite>> watchAll();
  Future<int> add({required String label, required String categoryKey, required int amount});
  Future<void> update(Favourite favourite);
  Future<void> delete(int id);
}
