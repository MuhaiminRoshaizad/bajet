import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../../core/dates/dates.dart';
import '../../../core/money/money.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../domain/ledger_models.dart';
import 'entry_tile.dart';
import 'ledger_providers.dart';
import 'log_sheet.dart';

/// Every entry, newest first, grouped by day.
final allEntriesProvider = StreamProvider<List<Entry>>((ref) => ref.watch(ledgerRepositoryProvider).watchSince(DateTime.utc(2000)));

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

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final today = ref.watch(todayProvider);
    final entries = ref.watch(allEntriesProvider);
    final categories = {for (final x in ref.watch(categoriesProvider).value ?? const <Category>[]) x.key: x};

    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: switch (entries) {
        AsyncValue(hasError: true) => Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Text("bajet couldn't read your entries. Close the app fully and open it again.", style: TextStyle(color: c.bad)),
          ),
        AsyncValue(:final value?) when value.isEmpty => Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Text('Nothing logged yet. Tap + to log your first spend.', style: TextStyle(color: c.muted)),
          ),
        AsyncValue(:final value?) => _HistoryList(rows: _group(value), categories: categories, today: today),
        _ => const SizedBox.shrink(),
      },
    );
  }

  static List<_Row> _group(List<Entry> entries) {
    final rows = <_Row>[];
    DateTime? current;
    for (final e in entries) {
      if (e.day != current) {
        current = e.day;
        final spent = entries.where((x) => x.day == e.day && !x.isIncome).fold(0, (s, x) => s + x.amount);
        rows.add(_DayRow(e.day, spent));
      }
      rows.add(_EntryRow(e));
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
      },
    );
  }

  String _dayTitle(DateTime day) {
    if (day == today) return 'Today';
    if (day == DateTime.utc(today.year, today.month, today.day - 1)) return 'Yesterday';
    return '${Dates.weekday(day)} ${Dates.full(day)}';
  }

  Future<bool> _confirmDelete(BuildContext context, Entry entry) async {
    final c = context.colors;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this entry?'),
        content: Text(
          '${entry.label ?? categories[entry.categoryKey]?.label ?? entry.categoryKey} ${Money.format(entry.amount)} on ${Dates.full(entry.day)}. '
          'Your balance will change by ${entry.isIncome ? '−' : '+'}${Money.format(entry.amount)}.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Keep')),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: c.bad, foregroundColor: c.onBad),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, Entry entry) async {
    final repo = ref.read(ledgerRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    await repo.delete(entry.id);
    messenger
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text('Deleted ${entry.label ?? categories[entry.categoryKey]?.label ?? entry.categoryKey}'),
        action: SnackBarAction(label: 'Undo', onPressed: () => repo.restore(entry)),
      ));
  }
}
