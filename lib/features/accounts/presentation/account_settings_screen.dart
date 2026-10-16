import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/money/money.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/card_group.dart';
import '../domain/account_models.dart';
import 'account_providers.dart';
import 'card_designer.dart';
import 'card_face.dart';
import 'delete_account.dart';

/// Every card's look in one list, the total card first: each row opens the
/// card designer, where an account can also be deleted, and a new account
/// can be added at the end.
class AccountSettingsScreen extends ConsumerWidget {
  const AccountSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final accounts = ref.watch(accountsProvider).value ?? const [];
    final total = ref.watch(totalCardLookProvider).value ?? const TotalCardLook();
    return Scaffold(
      appBar: AppBar(title: const Text('Accounts')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.l),
        children: [
          CardGroup(
            label: 'Cards',
            children: [
              _Row(
                swatch: total.color == null ? null : Color(total.color!),
                title: 'Total card',
                value: total.color == null ? 'Matches the app' : 'Your own colour',
                onTap: () => showTotalCardDesigner(context),
              ),
              for (final a in accounts)
                _Row(
                  swatch: Color(a.look.color),
                  title: a.name,
                  value: [a.nickname ?? kindLabel(a.kind), Money.format(a.balance)].join(' · '),
                  onTap: () async {
                    final choice = await showCardDesigner(context, a);
                    if (choice != null && context.mounted) {
                      await deleteAccount(ScaffoldMessenger.of(context), ref.read(accountRepositoryProvider), a, choice, accounts);
                    }
                  },
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.l),
          FilledButton.tonalIcon(onPressed: () => showAddAccount(context), icon: const Icon(Icons.add), label: const Text('Add an account')),
          const SizedBox(height: AppSpacing.m),
          Text(
            "Change a card's colour, finish and nickname here. Its balance changes only through what you log, money you move and the check-in.",
            style: TextStyle(color: c.muted, fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.swatch, required this.title, required this.value, required this.onTap});

  /// Null for the total card that follows the app: shown half light, half dark.
  final Color? swatch;
  final String title;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ListTile(
      minTileHeight: 64,
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
      leading: Container(
        width: 40,
        height: 26,
        decoration: BoxDecoration(
          color: swatch,
          gradient: swatch == null ? LinearGradient(colors: [c.ink, c.ink, c.background, c.background], stops: const [0, 0.5, 0.5, 1]) : null,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: c.line),
        ),
      ),
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: c.muted)),
      trailing: Icon(Icons.chevron_right_rounded, color: c.muted),
      onTap: onTap,
    );
  }
}
