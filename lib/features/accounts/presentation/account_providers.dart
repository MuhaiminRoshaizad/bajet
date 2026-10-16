import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../data/device_photo_colours.dart';
import '../data/drift_account_repository.dart';
import '../domain/account_models.dart';
import '../domain/account_repository.dart';
import '../domain/photo_colours.dart';

final accountRepositoryProvider = Provider<AccountRepository>((ref) => DriftAccountRepository(ref.watch(databaseProvider)));

/// Every account in display order, each with its balance now.
final accountsProvider = StreamProvider<List<Account>>((ref) => ref.watch(accountRepositoryProvider).watchAccounts());

/// Every transfer, newest first.
final transfersProvider = StreamProvider<List<Transfer>>((ref) => ref.watch(accountRepositoryProvider).watchTransfers());

final photoColoursProvider = Provider<PhotoColours>((ref) => DevicePhotoColours());

/// True while Your accounts is over Today, arriving or leaving: its cards
/// are flying from or back into Today's stack, which hides meanwhile so no
/// card shows twice.
class AccountsOnTop extends Notifier<bool> {
  @override
  bool build() => false;

  /// Ignored once the app itself is going away.
  void set(bool value) {
    if (ref.mounted) state = value;
  }
}

final accountsOnTopProvider = NotifierProvider<AccountsOnTop, bool>(AccountsOnTop.new);

final totalCardLookProvider = StreamProvider<TotalCardLook>((ref) => ref.watch(accountRepositoryProvider).watchTotalLook());
