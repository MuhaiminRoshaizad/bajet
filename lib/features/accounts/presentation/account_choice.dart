import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../domain/account_models.dart';

/// A labelled row of accounts to pick one from, each with its card's colour.
/// [unavailable] cannot be picked, such as the other side of a transfer.
class AccountChoice extends StatelessWidget {
  const AccountChoice({super.key, required this.label, required this.accounts, required this.selected, required this.onSelect, this.unavailable});

  final String label;
  final List<Account> accounts;
  final int? selected;
  final int? unavailable;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.colors.muted)),
        const SizedBox(height: AppSpacing.s),
        Wrap(spacing: AppSpacing.s, runSpacing: AppSpacing.s, children: [
          for (final a in accounts)
            ChoiceChip(
              key: ValueKey('$label-${a.id}'),
              avatar: CircleAvatar(backgroundColor: Color(a.look.color), radius: 8),
              label: Text(a.name),
              selected: a.id == selected,
              onSelected: a.id == unavailable ? null : (_) => onSelect(a.id),
            ),
        ]),
      ]);
}
