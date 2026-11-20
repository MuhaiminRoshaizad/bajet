import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../ledger/domain/ledger_models.dart';
import '../../ledger/presentation/entry_tile.dart';
import '../../ledger/presentation/ledger_providers.dart';
import '../../ledger/presentation/payback_tile.dart';
import '../domain/account_models.dart';
import 'account_providers.dart';
import 'transfer_tile.dart';

/// What has happened in one account, newest first: what was spent from it,
/// what came in, money paid back into it, and money moved in or out. The latest [limit] only; History
/// keeps the rest.
class AccountActivity extends ConsumerWidget {
  const AccountActivity({super.key, required this.account});

  final Account account;

  static const limit = 20;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final today = ref.watch(todayProvider);
    final accounts = ref.watch(accountsProvider).value ?? const <Account>[];
    final names = {for (final a in accounts) a.id: a.name};
    // Entries from before accounts existed carry none; they are the first's.
    final firstId = accounts.firstOrNull?.id;
    final all = ref.watch(allEntriesProvider).value ?? const <Entry>[];
    final entries = all.where((e) => (e.accountId ?? firstId) == account.id).toList();
    final paybacks = (ref.watch(paybacksProvider).value ?? const <Payback>[]).where((p) => (p.accountId ?? firstId) == account.id).toList();
    final transfers = (ref.watch(transfersProvider).value ?? const <Transfer>[]).where((t) => t.touches(account.id)).toList();
    final categories = {for (final x in ref.watch(categoriesProvider).value ?? const <Category>[]) x.key: x};

    final rows = _merge(entries, transfers, paybacks);
    String forName(Payback p) {
      final e = all.where((e) => e.id == p.entryId).firstOrNull;
      return e == null ? 'a shared spend' : e.label ?? categories[e.categoryKey]?.label ?? e.categoryKey;
    }

    final shown = rows.take(limit).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.l, AppSpacing.m, AppSpacing.l, AppSpacing.xxl),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${account.name} activity', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        const SizedBox(height: AppSpacing.xs),
        if (shown.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.m),
            child: Text(
              'Nothing yet. What you spend from ${account.name}, pay into it or move in or out shows here.',
              style: TextStyle(color: c.muted),
            ),
          ),
        for (final r in shown)
          switch (r) {
            Entry() => EntryTile(entry: r, category: categories[r.categoryKey], today: today),
            Transfer() => TransferTile(transfer: r, names: names, today: today, seenFrom: account.id),
            Payback() => PaybackTile(payback: r, forName: forName(r), today: today),
            _ => const SizedBox.shrink(),
          },
        if (rows.length > limit)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.s),
            child: Text('The latest $limit. History has the rest.', style: TextStyle(color: c.muted, fontSize: 13)),
          ),
      ]),
    );
  }

  /// Newest day first; within a day entries, then transfers, then
  /// paybacks, each in the order given, as in History.
  static List<Object> _merge(List<Entry> entries, List<Transfer> transfers, List<Payback> paybacks) {
    final rows = [
      for (final (i, e) in entries.indexed) (e.day, 0, i, e as Object),
      for (final (i, t) in transfers.indexed) (t.day, 1, i, t as Object),
      for (final (i, p) in paybacks.indexed) (p.day, 2, i, p as Object),
    ]..sort((a, b) => b.$1 != a.$1 ? b.$1.compareTo(a.$1) : a.$2 != b.$2 ? a.$2.compareTo(b.$2) : a.$3.compareTo(b.$3));
    return [for (final r in rows) r.$4];
  }
}
