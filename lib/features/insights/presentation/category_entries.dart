import 'package:flutter/material.dart';

import '../../ledger/domain/ledger_models.dart';
import '../../ledger/presentation/entry_tile.dart';

/// The entries behind one slice of the ring, newest first: the first few,
/// then all of them once asked for. Each opens as it does in History.
class CategoryEntries extends StatefulWidget {
  const CategoryEntries({super.key, required this.entries, required this.categories, required this.today, required this.onOpen});

  final List<Entry> entries;
  final Map<String, Category> categories;
  final DateTime today;
  final ValueChanged<Entry> onOpen;

  /// How many show before "Show all".
  static const first = 5;

  @override
  State<CategoryEntries> createState() => _CategoryEntriesState();
}

class _CategoryEntriesState extends State<CategoryEntries> {
  var _all = false;

  @override
  Widget build(BuildContext context) {
    final entries = widget.entries;
    final shown = _all ? entries : entries.take(CategoryEntries.first);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final e in shown)
          EntryTile(key: ValueKey('ring-entry-${e.id}'), entry: e, category: widget.categories[e.categoryKey], today: widget.today, onTap: () => widget.onOpen(e)),
        if (!_all && entries.length > CategoryEntries.first)
          TextButton(onPressed: () => setState(() => _all = true), child: Text('Show all ${entries.length}')),
      ],
    );
  }
}
