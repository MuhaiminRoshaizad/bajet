import 'package:flutter/material.dart';

import '../domain/ledger_models.dart';
import 'entry_tile.dart';

/// The entries behind a figure, such as a slice of Insights' ring, newest
/// first: the first few, then all of them once asked for. Each opens as it
/// does in History.
class EntryDrawer extends StatefulWidget {
  const EntryDrawer({super.key, required this.entries, required this.categories, required this.today, required this.onOpen});

  final List<Entry> entries;
  final Map<String, Category> categories;
  final DateTime today;
  final ValueChanged<Entry> onOpen;

  /// How many show before "Show all".
  static const first = 5;

  @override
  State<EntryDrawer> createState() => _EntryDrawerState();
}

class _EntryDrawerState extends State<EntryDrawer> {
  var _all = false;

  @override
  Widget build(BuildContext context) {
    final entries = widget.entries;
    final shown = _all ? entries : entries.take(EntryDrawer.first);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final e in shown)
          EntryTile(key: ValueKey(('drawer-entry', e.id)), entry: e, category: widget.categories[e.categoryKey], today: widget.today, onTap: () => widget.onOpen(e)),
        if (!_all && entries.length > EntryDrawer.first)
          TextButton(onPressed: () => setState(() => _all = true), child: Text('Show all ${entries.length}')),
      ],
    );
  }
}
