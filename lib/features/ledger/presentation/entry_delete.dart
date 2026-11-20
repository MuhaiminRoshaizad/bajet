import 'package:flutter/material.dart';

import '../../../core/dates/dates.dart';
import '../../../core/money/money.dart';
import '../../../core/widgets/confirm_delete.dart';
import '../../../core/widgets/done_bar.dart';
import '../domain/ledger_models.dart';
import '../domain/ledger_repository.dart';

/// Asks before [entry], called [name], is deleted, saying what that does to
/// the balance: all that was paid comes back, less any money already paid
/// back toward it, which goes with it.
Future<bool> confirmEntryDelete(BuildContext context, Entry entry, {required String name, required int paidBack}) {
  final change = entry.isIncome ? -entry.amount : entry.paid - paidBack;
  return confirmDelete(
    context,
    title: 'Delete this entry?',
    message: '$name ${Money.format(entry.paid)} on ${Dates.full(entry.day)}. '
        'Your balance will change by ${change < 0 ? '−' : '+'}${Money.format(change.abs())}.'
        '${paidBack > 0 ? ' The ${Money.format(paidBack)} paid back toward it goes too.' : ''}',
  );
}

/// Deletes [entry] and shows a bar whose Undo puts it back with its
/// paybacks.
Future<void> deleteEntry(LedgerRepository repo, ScaffoldMessengerState messenger, Entry entry, {required String name}) async {
  final paybacks = await repo.delete(entry.id);
  showBar(messenger, 'Deleted $name', undo: () => repo.restore(entry, paybacks: paybacks));
}
