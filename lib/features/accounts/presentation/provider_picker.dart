import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../domain/account_models.dart';
import '../domain/known_providers.dart';
import 'card_palette.dart';

/// Which bank or e-wallet. Tapping opens a sheet of every known one,
/// grouped, each with a dot in the colour its card starts in, to scroll
/// and pick from. A search box at its top filters it, and only opens the
/// keyboard when tapped; a name that is not listed can be used from the
/// last row.
class ProviderPicker extends StatelessWidget {
  const ProviderPicker({super.key, required this.kind, required this.controller, required this.onChoose, this.errorText});

  final AccountKind kind;

  /// Holds the name chosen; whatever it holds is the name used.
  final TextEditingController controller;
  final ValueChanged<String> onChoose;
  final String? errorText;

  String get _label => kind == AccountKind.bank ? 'Which bank?' : 'Which e-wallet?';

  Future<void> _open(BuildContext context) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _ProviderSheet(kind: kind, title: _label, current: controller.text),
    );
    if (picked != null) onChoose(picked);
  }

  @override
  Widget build(BuildContext context) => TextField(
        autofillHints: null,
        controller: controller,
        readOnly: true,
        onTap: () => _open(context),
        decoration: InputDecoration(
          labelText: _label,
          hintText: 'Choose',
          errorText: errorText,
          suffixIcon: const Icon(Icons.expand_more_rounded),
        ),
      );
}

class _ProviderSheet extends StatefulWidget {
  const _ProviderSheet({required this.kind, required this.title, required this.current});

  final AccountKind kind;
  final String title;
  final String current;

  @override
  State<_ProviderSheet> createState() => _ProviderSheetState();
}

class _ProviderSheetState extends State<_ProviderSheet> {
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  /// Every provider under its heading; while searching, only the matches,
  /// and a last row to use what was typed when nothing listed is exactly it.
  List<Widget> _rows(BuildContext context) {
    final c = context.colors;
    final typed = _query.text.trim();
    Widget row(String name) => _Row(
          leading: _Dot(color: Color(startingSwatch(widget.kind, name).color)),
          label: Text(name),
          selected: name == widget.current,
          onTap: () => Navigator.of(context).pop(name),
        );
    if (typed.isEmpty) {
      final heading = TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.6, color: c.muted);
      return [
        for (final (group, names) in providerGroups[widget.kind] ?? const <(String, List<String>)>[]) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.m, AppSpacing.l, AppSpacing.m, AppSpacing.xs),
            child: Text(group.toUpperCase(), style: heading),
          ),
          for (final name in names) row(name),
        ],
      ];
    }
    final hits = providersMatching(widget.kind, typed);
    return [
      for (final name in hits) row(name),
      if (!hits.any((h) => h.toLowerCase() == typed.toLowerCase()))
        _Row(
          leading: Icon(Icons.add_rounded, size: 18, color: c.primary),
          label: Text('Not listed? Use “$typed”'),
          onTap: () => Navigator.of(context).pop(typed),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) => SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.75,
        child: Padding(
          padding: EdgeInsets.fromLTRB(AppSpacing.l, 0, AppSpacing.l, MediaQuery.viewInsetsOf(context).bottom),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: AppSpacing.m),
              // The list is there to scroll first; this waits for a tap.
              TextField(
                autofillHints: null,
                key: const ValueKey('provider-search'),
                controller: _query,
                textInputAction: TextInputAction.search,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: widget.kind == AccountKind.bank ? 'Search banks, e.g. Maybank' : 'Search e-wallets, e.g. GrabPay',
                  prefixIcon: const Icon(Icons.search_rounded),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Expanded(child: ListView(padding: const EdgeInsets.only(bottom: AppSpacing.l), children: _rows(context))),
            ],
          ),
        ),
      );
}

class _Row extends StatelessWidget {
  const _Row({required this.leading, required this.label, required this.onTap, this.selected = false});

  final Widget leading;
  final Widget label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.small),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
          child: Row(
            children: [
              leading,
              const SizedBox(width: AppSpacing.m),
              Expanded(
                child: DefaultTextStyle.merge(
                  style: TextStyle(fontSize: 15, fontWeight: selected ? FontWeight.w700 : FontWeight.w500, color: selected ? c.primary : c.ink),
                  child: label,
                ),
              ),
              if (selected) Icon(Icons.check_rounded, size: 20, color: c.primary),
            ],
          ),
        ),
      ),
    );
  }
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
