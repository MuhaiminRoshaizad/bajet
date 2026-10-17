import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../accounts/presentation/account_providers.dart';
import '../../insights/presentation/insights_providers.dart';
import '../../ledger/presentation/ledger_providers.dart';
import '../domain/report.dart';

/// Each account over [range], for the report and the coach. Null until the
/// accounts, the entries and the range's figures have loaded.
final reportAccountsProvider = Provider.family<List<AccountLine>?, InsightsRange>((ref, range) {
  final i = ref.watch(insightsForProvider(range));
  final accounts = ref.watch(accountsProvider).value;
  final all = ref.watch(allEntriesProvider).value;
  if (i == null || accounts == null || all == null) return null;
  return byAccount(accounts, entriesIn(i, all));
});
