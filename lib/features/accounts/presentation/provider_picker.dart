import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../domain/account_models.dart';
import '../domain/known_providers.dart';
import 'card_palette.dart';

/// Which bank or e-wallet: a dropdown of every known one, grouped, each with
/// a dot in the colour its card starts in. Typing filters it; a name that is
/// not listed can still be used from the last row, or simply left typed.
class ProviderPicker extends StatefulWidget {
  const ProviderPicker({super.key, required this.kind, required this.controller, required this.onChoose, this.errorText});

  final AccountKind kind;

  /// Holds what is typed; whatever it holds is the name used.
  final TextEditingController controller;
  final ValueChanged<String> onChoose;
  final String? errorText;

  /// Room for about five rows above the keyboard.
  static const menuHeight = 300.0;

  @override
  State<ProviderPicker> createState() => _ProviderPickerState();
}

/// A row's value: a provider's name, or a group heading, which is never
/// picked.
typedef _Row = ({String name, bool heading});

class _ProviderPickerState extends State<ProviderPicker> {
  List<DropdownMenuEntry<_Row>> _entries(BuildContext context) {
    final c = context.colors;
    final heading = TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.6, color: c.muted);
    return [
      for (final (group, names) in providerGroups[widget.kind] ?? const <(String, List<String>)>[]) ...[
        DropdownMenuEntry(value: (name: group, heading: true), label: group, enabled: false, labelWidget: Text(group.toUpperCase(), style: heading)),
        for (final name in names)
          DropdownMenuEntry(
            value: (name: name, heading: false),
            label: name,
            leadingIcon: _Dot(color: Color(startingSwatch(widget.kind, name).color)),
          ),
      ],
    ];
  }

  /// Matching names under their headings; with a name typed that is not
  /// listed, a last row to use it as it is.
  List<DropdownMenuEntry<_Row>> _filter(List<DropdownMenuEntry<_Row>> all, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return all;
    final hits = all.where((e) => !e.value.heading && e.label.toLowerCase().contains(q)).toList();
    final typed = query.trim();
    return [
      ...hits,
      if (!hits.any((e) => e.label.toLowerCase() == q))
        DropdownMenuEntry(
          value: (name: typed, heading: false),
          label: typed,
          leadingIcon: const Icon(Icons.add, size: 18),
          labelWidget: Text('Not listed? Use “$typed”'),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) => DropdownMenu<_Row>(
        controller: widget.controller,
        dropdownMenuEntries: _entries(context),
        enableFilter: true,
        enableSearch: false,
        requestFocusOnTap: true,
        expandedInsets: EdgeInsets.zero,
        menuHeight: ProviderPicker.menuHeight,
        label: Text(widget.kind == AccountKind.bank ? 'Which bank?' : 'Which e-wallet?'),
        hintText: 'Search or choose',
        errorText: widget.errorText,
        textInputAction: TextInputAction.next,
        filterCallback: _filter,
        onSelected: (row) {
          if (row == null || row.heading) return;
          widget.onChoose(row.name);
        },
      );
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: context.colors.line)),
      );
}
