import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../data/drift_account_repository.dart';
import '../domain/account_models.dart';
import '../domain/account_repository.dart';

final accountRepositoryProvider = Provider<AccountRepository>((ref) => DriftAccountRepository(ref.watch(databaseProvider)));

/// Every account in display order, each with its balance now.
final accountsProvider = StreamProvider<List<Account>>((ref) => ref.watch(accountRepositoryProvider).watchAccounts());

final totalCardLookProvider = StreamProvider<TotalCardLook>((ref) => ref.watch(accountRepositoryProvider).watchTotalLook());
