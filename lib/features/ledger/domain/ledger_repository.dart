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
  Future<void> delete(int id);

  /// Puts back an entry removed by [delete], keeping its id, for undo.
  Future<void> restore(Entry entry);
}

abstract interface class FavouriteRepository {
  Stream<List<Favourite>> watchAll();
  Future<int> add({required String label, required String categoryKey, required int amount});
  Future<void> update(Favourite favourite);
  Future<void> delete(int id);
}
