import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../../core/dates/dates.dart';
import '../../../core/money/money.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/confirm_delete.dart';
import '../../../core/widgets/done_bar.dart';
import '../../../core/widgets/empty_state.dart';
import '../../accounts/domain/account_models.dart';
import '../../accounts/presentation/account_providers.dart';
import '../../accounts/presentation/transfer_tile.dart';
import '../domain/ledger_models.dart';
import 'entry_tile.dart';
import 'ledger_providers.dart';
import 'log_sheet.dart';

/// Every entry and every transfer, newest first, grouped by day. Transfers
/// show in their own blue rows and never count in a day's spending.
sealed class _Row {}

class _DayRow extends _Row {
  _DayRow(this.day, this.spent);
  final DateTime day;
  final int spent;
}

class _EntryRow extends _Row {
  _EntryRow(this.entry);
  final Entry entry;
}

class _TransferRow extends _Row {
  _TransferRow(this.transfer);
  final Transfer transfer;
}

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayProvider);
    final entries = ref.watch(allEntriesProvider);
    final transfers = ref.watch(transfersProvider).value ?? const <Transfer>[];
    final categories = {for (final x in ref.watch(categoriesProvider).value ?? const <Category>[]) x.key: x};

    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: switch (entries) {
        AsyncValue(hasError: true) => const EmptyState(
            icon: Icons.error_outline_rounded,
            title: "bajet couldn't read your entries",
            message: 'Close the app fully and open it again. Your entries are still on the phone.',
          ),
        AsyncValue(:final value?) when value.isEmpty && transfers.isEmpty => EmptyState(
            icon: Icons.receipt_long_rounded,
            title: 'Nothing logged yet',
            message: 'Every spend and income you log appears here, newest first.',
            actionLabel: 'Log a spend',
            onAction: () => showLogSheet(context),
          ),
        AsyncValue(:final value?) => _HistoryList(rows: _group(value, transfers), categories: categories, today: today),
        _ => const SizedBox.shrink(),
      },
    );
  }

  static List<_Row> _group(List<Entry> entries, List<Transfer> transfers) {
    final rows = <_Row>[];
    final days = {...entries.map((e) => e.day), ...transfers.map((t) => t.day)}.toList()..sort((a, b) => b.compareTo(a));
    for (final day in days) {
      final ofDay = entries.where((e) => e.day == day);
      rows.add(_DayRow(day, ofDay.where((x) => !x.isIncome).fold(0, (s, x) => s + x.amount)));
      rows.addAll(ofDay.map(_EntryRow.new));
      rows.addAll(transfers.where((t) => t.day == day).map(_TransferRow.new));
    }
    return rows;
  }
}

class _HistoryList extends ConsumerWidget {
  const _HistoryList({required this.rows, required this.categories, required this.today});

  final List<_Row> rows;
  final Map<String, Category> categories;
  final DateTime today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final names = {for (final a in ref.watch(accountsProvider).value ?? const <Account>[]) a.id: a.name};
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(AppSpacing.l, 0, AppSpacing.l, AppSpacing.xxl),
      itemCount: rows.length,
      itemBuilder: (context, i) => switch (rows[i]) {
        _DayRow(:final day, :final spent) => Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xs, AppSpacing.l, AppSpacing.xs, AppSpacing.xs),
            child: Row(
              children: [
                Text(_dayTitle(day), style: TextStyle(color: c.muted, fontWeight: FontWeight.w600)),
                const Spacer(),
                if (spent > 0) Text('−${Money.format(spent)}', style: TextStyle(color: c.muted, fontFeatures: const [FontFeature.tabularFigures()])),
              ],
            ),
          ),
        _EntryRow(:final entry) => Dismissible(
            key: ValueKey('entry-${entry.id}'),
            direction: DismissDirection.endToStart,
            confirmDismiss: (_) => _confirmDelete(context, entry),
            onDismissed: (_) => _delete(context, ref, entry),
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: AppSpacing.xl),
              decoration: BoxDecoration(color: c.bad, borderRadius: BorderRadius.circular(AppRadii.control)),
              child: Text('Delete', style: TextStyle(color: c.onBad, fontWeight: FontWeight.w700)),
            ),
            child: EntryTile(
              entry: entry,
              category: categories[entry.categoryKey],
              today: today,
              onTap: () => showLogSheet(context, editing: entry),
            ),
          ),
        _TransferRow(:final transfer) => Dismissible(
            key: ValueKey('transfer-${transfer.id}'),
            direction: DismissDirection.endToStart,
            confirmDismiss: (_) => confirmDelete(
              context,
              title: 'Delete this move?',
              message: '${Money.format(transfer.amount)} from ${names[transfer.fromId]} to ${names[transfer.toId]} on ${Dates.full(transfer.day)}. '
                  'Both balances go back to before it; your total does not change.',
            ),
            onDismissed: (_) => _deleteTransfer(context, ref, transfer),
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: AppSpacing.xl),
              decoration: BoxDecoration(color: c.bad, borderRadius: BorderRadius.circular(AppRadii.control)),
              child: Text('Delete', style: TextStyle(color: c.onBad, fontWeight: FontWeight.w700)),
            ),
            child: TransferTile(transfer: transfer, names: names, today: today),
          ),
      },
    );
  }

  String _dayTitle(DateTime day) {
    if (day == today) return 'Today';
    if (day == DateTime.utc(today.year, today.month, today.day - 1)) return 'Yesterday';
    return '${Dates.weekday(day)} ${Dates.full(day)}';
  }

  Future<bool> _confirmDelete(BuildContext context, Entry entry) => confirmDelete(
        context,
        title: 'Delete this entry?',
        message: '${entry.label ?? categories[entry.categoryKey]?.label ?? entry.categoryKey} ${Money.format(entry.amount)} on ${Dates.full(entry.day)}. '
            'Your balance will change by ${entry.isIncome ? '−' : '+'}${Money.format(entry.amount)}.',
      );

  Future<void> _delete(BuildContext context, WidgetRef ref, Entry entry) async {
    final repo = ref.read(ledgerRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    await repo.delete(entry.id);
    showBar(messenger, 'Deleted ${entry.label ?? categories[entry.categoryKey]?.label ?? entry.categoryKey}', undo: () => repo.restore(entry));
  }

  Future<void> _deleteTransfer(BuildContext context, WidgetRef ref, Transfer t) async {
    final repo = ref.read(accountRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    await repo.deleteTransfer(t.id);
    showBar(
      messenger,
      'Deleted the move of ${Money.format(t.amount)}',
      undo: () => repo.transfer(fromId: t.fromId, toId: t.toId, amount: t.amount, day: t.day, note: t.note),
    );
  }
}
