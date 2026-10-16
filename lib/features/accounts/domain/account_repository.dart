import 'account_models.dart';

/// Storage-agnostic access to accounts and the money moved between them.
abstract interface class AccountRepository {
  /// Every account in display order, each with its balance now.
  Stream<List<Account>> watchAccounts();

  /// Opens an account holding [AccountDraft.balance], placed after the
  /// others.
  Future<int> addAccount(AccountDraft draft);

  /// Puts the accounts in the order of [ids], first to last: the order of
  /// Today's stack, Your accounts, the swipe between cards and every picker.
  Future<void> reorderAccounts(List<int> ids);

  /// Changes an account's name, nickname and card. Its balance changes only
  /// through entries, transfers and check-ins.
  Future<void> updateAccount(Account account);

  /// Corrects what an account held on the opening date, for a figure given
  /// wrongly. Every balance of it since moves by the difference; nothing is
  /// logged.
  Future<void> setOpeningBalance(int accountId, int balance);

  /// Moves [amount] from one account to another on [day]. Neither spending
  /// nor income, so only the two accounts' balances change.
  Future<int> transfer({required int fromId, required int toId, required int amount, required DateTime day, String? note});

  /// Every transfer, newest first.
  Stream<List<Transfer>> watchTransfers();

  /// Takes back a transfer, for undo.
  Future<void> deleteTransfer(int id);

  Stream<TotalCardLook> watchTotalLook();
  Future<void> saveTotalLook(TotalCardLook look);
}
