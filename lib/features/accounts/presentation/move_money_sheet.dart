import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../../core/money/money.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/validation/ringgit_cents_formatter.dart';
import '../../../core/widgets/money_field.dart';
import '../domain/account_models.dart';
import 'account_providers.dart';

/// Moves money from one account to another, starting from [fromId]. It is
/// neither spending nor income, so the week, Runway and Insights stay as
/// they are; only the two balances change.
Future<void> showMoveMoney(BuildContext context, {required int fromId}) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _MoveMoney(fromId: fromId, messenger: ScaffoldMessenger.of(context)),
    );

class _MoveMoney extends ConsumerStatefulWidget {
  const _MoveMoney({required this.fromId, required this.messenger});

  final int fromId;

  /// The page's messenger, which outlives the sheet, for the undo.
  final ScaffoldMessengerState messenger;

  @override
  ConsumerState<_MoveMoney> createState() => _MoveMoneyState();
}

class _MoveMoneyState extends ConsumerState<_MoveMoney> {
  final _amount = TextEditingController();
  late int _from = widget.fromId;
  int? _to;

  @override
  void initState() {
    super.initState();
    _amount.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _move(List<Account> accounts) async {
    final amount = RinggitCentsFormatter.parse(_amount.text);
    final to = _to;
    if (amount <= 0 || to == null) return;
    final repo = ref.read(accountRepositoryProvider);
    final id = await repo.transfer(fromId: _from, toId: to, amount: amount, day: ref.read(todayProvider));
    String name(int id) => accounts.firstWhere((a) => a.id == id).name;
    if (mounted) Navigator.of(context).pop();
    widget.messenger
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text('Moved ${Money.format(amount)} from ${name(_from)} to ${name(to)}'),
        action: SnackBarAction(label: 'Undo', onPressed: () => repo.deleteTransfer(id)),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final accounts = ref.watch(accountsProvider).value ?? const [];
    // Starts on the first other account, so it is one tap from done.
    final to = _to ??= accounts.where((a) => a.id != _from).firstOrNull?.id;
    final from = accounts.where((a) => a.id == _from).firstOrNull;
    final into = accounts.where((a) => a.id == to).firstOrNull;
    final amount = RinggitCentsFormatter.parse(_amount.text);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Move money', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.l),
          MoneyField(controller: _amount, label: 'Amount', hint: 'e.g. 100.00', textInputAction: TextInputAction.done),
          _Accounts(label: 'From', accounts: accounts, selected: _from, other: to, onSelect: (id) => setState(() => _from = id)),
          _Accounts(label: 'To', accounts: accounts, selected: to, other: _from, onSelect: (id) => setState(() => _to = id)),
          if (from != null && into != null) ...[
            const SizedBox(height: AppSpacing.l),
            Container(
              padding: const EdgeInsets.all(AppSpacing.m),
              decoration: BoxDecoration(color: c.well, borderRadius: BorderRadius.circular(AppRadii.small)),
              child: Column(children: [
                _Change(name: from.name, before: from.balance, after: from.balance - amount),
                const SizedBox(height: AppSpacing.xs),
                _Change(name: into.name, before: into.balance, after: into.balance + amount),
                const Divider(height: AppSpacing.l),
                Row(children: [const Expanded(child: Text('Total')), Text('No change', style: TextStyle(color: c.muted))]),
              ]),
            ),
          ],
          const SizedBox(height: AppSpacing.m),
          Text('Not spending or income. Your week, Runway and Insights stay as they are.', style: TextStyle(color: c.good, fontSize: 13)),
          const SizedBox(height: AppSpacing.xl),
          FilledButton(
            onPressed: amount > 0 && to != null ? () => _move(accounts) : null,
            child: Text(amount > 0 ? 'Move ${Money.format(amount)}' : 'Enter an amount to move'),
          ),
        ]),
      ),
    );
  }
}

/// A row of accounts to choose from; [other] is the one on the other side,
/// which cannot also be this side.
class _Accounts extends StatelessWidget {
  const _Accounts({required this.label, required this.accounts, required this.selected, required this.other, required this.onSelect});

  final String label;
  final List<Account> accounts;
  final int? selected;
  final int? other;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: AppSpacing.l),
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.colors.muted)),
        const SizedBox(height: AppSpacing.s),
        Wrap(spacing: AppSpacing.s, runSpacing: AppSpacing.s, children: [
          for (final a in accounts)
            ChoiceChip(
              key: ValueKey('$label-${a.id}'),
              avatar: CircleAvatar(backgroundColor: Color(a.look.color), radius: 8),
              label: Text(a.name),
              selected: a.id == selected,
              onSelected: a.id == other ? null : (_) => onSelect(a.id),
            ),
        ]),
      ]);
}

class _Change extends StatelessWidget {
  const _Change({required this.name, required this.before, required this.after});

  final String name;
  final int before;
  final int after;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    // The figures shrink to fit a narrow phone or a large font rather than
    // run off the edge.
    return Row(children: [
      Expanded(child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis)),
      const SizedBox(width: AppSpacing.s),
      Flexible(
        flex: 2,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerRight,
          child: Text.rich(TextSpan(children: [
            TextSpan(text: '${Money.format(before)} → ', style: TextStyle(color: c.muted)),
            TextSpan(text: Money.format(after), style: TextStyle(fontWeight: FontWeight.w700, color: after < 0 ? c.bad : c.ink)),
          ])),
        ),
      ),
    ]);
  }
}
