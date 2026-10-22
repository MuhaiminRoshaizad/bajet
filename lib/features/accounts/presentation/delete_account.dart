import 'package:flutter/material.dart';

import '../../../core/money/money.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/confirm_delete.dart';
import '../../../core/widgets/done_bar.dart';
import '../domain/account_models.dart';
import '../domain/account_repository.dart';
import 'account_choice.dart';

/// The user's answer to deleting an account: the account its history moves
/// to, or null when that goes too.
class DeleteChoice {
  const DeleteChoice({this.moveTo});

  final int? moveTo;
}

String _called(Account a) => a.called;

/// Asks before [account] is deleted. One never used gets a plain confirm;
/// one with history asks where that goes, moving it by default so no past
/// figure changes. Null when the user kept it.
Future<DeleteChoice?> askDeleteAccount(BuildContext context, AccountRepository repo, Account account, List<Account> all) async {
  final use = await repo.accountUse(account.id);
  if (!context.mounted) return null;
  if (use.isEmpty) {
    final drops = account.balance == 0 ? '' : ' Your total drops by ${Money.format(account.balance)}.';
    final yes = await confirmDelete(context, title: 'Delete ${_called(account)}?', message: 'Nothing has been logged to it.$drops');
    return yes ? const DeleteChoice() : null;
  }
  return showDialog<DeleteChoice>(
    context: context,
    builder: (_) => _DeleteDialog(account: account, use: use, others: [for (final a in all) if (a.id != account.id) a]),
  );
}

/// Deletes the account as chosen, then says what happened with an Undo.
/// Takes the messenger rather than a context, since the page it was asked
/// from may already have closed.
Future<void> deleteAccount(ScaffoldMessengerState messenger, AccountRepository repo, Account account, DeleteChoice choice, List<Account> all) async {
  final removal = await repo.deleteAccount(account.id, moveTo: choice.moveTo);
  final to = all.where((a) => a.id == choice.moveTo).firstOrNull;
  showBar(
    messenger,
    to == null ? 'Deleted ${_called(account)}' : 'Deleted ${_called(account)}. Its history moved to ${_called(to)}.',
    undo: () => repo.restoreAccount(removal),
  );
}

String _count(int n, String one, String many) => '$n ${n == 1 ? one : many}';

class _DeleteDialog extends StatefulWidget {
  const _DeleteDialog({required this.account, required this.use, required this.others});

  final Account account;
  final AccountUse use;
  final List<Account> others;

  @override
  State<_DeleteDialog> createState() => _DeleteDialogState();
}

class _DeleteDialogState extends State<_DeleteDialog> {
  late int _moveTo = widget.others.first.id;
  bool _move = true;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final use = widget.use;
    final balance = widget.account.balance;
    final uses = [
      if (use.entries > 0) _count(use.entries, 'entry', 'entries'),
      if (use.transfers > 0) _count(use.transfers, 'transfer', 'transfers'),
      if (use.bills.isNotEmpty) _count(use.bills.length, 'bill', 'bills'),
    ];
    final listed = uses.length < 2 ? uses.single : '${uses.sublist(0, uses.length - 1).join(', ')} and ${uses.last}';
    final one = use.entries + use.transfers + use.bills.length == 1;
    final bills = use.bills.isEmpty ? '' : ' Also deletes ${use.bills.length == 1 ? 'the bill' : 'the bills'} ${use.bills.map((b) => '"$b"').join(', ')}.';
    return AlertDialog(
      title: Text('Delete ${_called(widget.account)}?'),
      scrollable: true,
      contentPadding: const EdgeInsets.fromLTRB(AppSpacing.s, AppSpacing.l, AppSpacing.s, 0),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
          child: Text('$listed ${one ? 'uses' : 'use'} it.', style: TextStyle(color: c.muted)),
        ),
        const SizedBox(height: AppSpacing.s),
        // Moving is first and already chosen: it is the answer that leaves
        // every past figure as it was.
        RadioGroup<bool>(
          groupValue: _move,
          onChanged: (v) => setState(() => _move = v ?? true),
          child: Column(children: [
            RadioListTile(
              value: true,
              title: const Text('Move them to another account'),
              subtitle: Text(balance == 0 ? 'Your total and past weeks stay the same.' : '${Money.format(balance)} goes with them. Your total stays the same.'),
            ),
            if (_move)
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.xxxl, 0, AppSpacing.l, AppSpacing.s),
                child: AccountChoice(label: 'Move to', accounts: widget.others, selected: _moveTo, onSelect: (id) => setState(() => _moveTo = id)),
              ),
            RadioListTile(
              value: false,
              title: const Text('Delete them too'),
              subtitle: Text('Past weeks and Insights lose them${balance == 0 ? '' : ', and your total drops by ${Money.format(balance)}'}.$bills'),
            ),
          ]),
        ),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Keep')),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(DeleteChoice(moveTo: _move ? _moveTo : null)),
          style: FilledButton.styleFrom(backgroundColor: c.bad, foregroundColor: c.onBad),
          child: const Text('Delete'),
        ),
      ],
    );
  }
}
