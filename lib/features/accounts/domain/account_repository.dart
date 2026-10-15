import 'account_models.dart';

/// Storage-agnostic access to accounts and the money moved between them.
abstract interface class AccountRepository {
  /// Every account in display order, each with its balance now.
  Stream<List<Account>> watchAccounts();

  /// Opens an account holding [AccountDraft.balance], placed after the
  /// others.
  Future<int> addAccount(AccountDraft draft);

  /// Changes an account's name, nickname and card. Its balance changes only
  /// through entries, transfers and check-ins.
  Future<void> updateAccount(Account account);

  /// Moves [amount] from one account to another on [day]. Neither spending
  /// nor income, so only the two accounts' balances change.
  Future<int> transfer({required int fromId, required int toId, required int amount, required DateTime day, String? note});

  Stream<TotalCardLook> watchTotalLook();
  Future<void> saveTotalLook(TotalCardLook look);
}
