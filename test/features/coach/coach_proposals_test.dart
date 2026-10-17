import 'package:bajet/features/coach/domain/coach_lookups.dart';
import 'package:bajet/features/coach/domain/coach_proposals.dart';
import 'package:bajet/features/plan/domain/plan_models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'coach_lookups_test.dart' show data, d;

void main() {
  test('a log the user asked for becomes a card with the category and account it names', () {
    final (result, p) = propose('bajet_propose_log', {'kind': 'spending', 'amount_rm': 12.5, 'category': 'food', 'label': 'Lunch', 'account': 'wallet'}, data);
    expect(result.failed, isFalse);
    expect(result.text, contains('Nothing is logged unless they tap Log it.'));
    final log = p! as LogProposal;
    expect((log.draft.amount, log.draft.categoryKey, log.draft.accountId, log.draft.day, log.draft.label), (1250, 'food', 2, d(10, 15), 'Lunch'));
    expect(log.rows, [('What', 'Lunch · Food'), ('From', 'Wallet'), ('Day', '15/10/2026')]);
  });

  test('a slip in the amount never reaches a card', () {
    for (final amount in [0, -5, 100000.01, 'lots']) {
      final (result, p) = propose('bajet_propose_log', {'kind': 'spending', 'amount_rm': amount, 'category': 'Food'}, data);
      expect((result.failed, p), (true, null), reason: '$amount');
    }
    final (move, none) = propose('bajet_propose_move', {'amount_rm': 50000, 'from': 'Main account', 'to': 'Cash'}, data);
    expect((move.failed, none), (true, null));
  });

  test('an unknown category or account is refused with the real ones listed, so the model can ask again', () {
    final (r1, _) = propose('bajet_propose_log', {'kind': 'spending', 'amount_rm': 5, 'category': 'Crypto'}, data);
    expect(r1.text, contains('The categories are: Food, Transport'));
    final (r2, _) = propose('bajet_propose_log', {'kind': 'spending', 'amount_rm': 5, 'category': 'Food', 'account': 'Swiss bank'}, data);
    expect(r2.text, contains('The accounts are: Main account, Wallet.'));
  });

  test('a log cannot be dated in the future or more than a year back', () {
    for (final day in ['2026-10-16', '2025-10-14', '15/10/2026']) {
      final (r, p) = propose('bajet_propose_log', {'kind': 'spending', 'amount_rm': 5, 'category': 'Food', 'day': day}, data);
      expect((r.failed, p), (true, null), reason: day);
    }
  });

  test('a move needs two different accounts of the user', () {
    final (ok, p) = propose('bajet_propose_move', {'amount_rm': 50, 'from': 'Main account', 'to': 'wallet'}, data);
    expect(ok.failed, isFalse);
    final move = p! as MoveProposal;
    expect((move.fromId, move.toId, move.amount), (1, 2, 5000));
    final (same, _) = propose('bajet_propose_move', {'amount_rm': 50, 'from': 'Cash', 'to': 'Wallet'}, data);
    expect(same.failed, isTrue);
  });

  test('marking a bill paid needs an active bill of that name, and has no Undo', () {
    final rent = RecurringItem(id: 7, name: 'Rent', amount: 50000, categoryKey: 'bills', isIncome: false, nextDue: d(11, 1));
    final withBill = CoachData(
      today: data.today,
      settings: data.settings,
      balance: data.balance,
      entries: data.entries,
      categories: data.categories,
      accounts: data.accounts,
      rules: data.rules,
      recurring: [rent],
      projection: null,
      upcoming: const [],
    );
    final (r, p) = propose('bajet_propose_bill_paid', {'bill': 'rent'}, withBill);
    expect(r.failed, isFalse);
    expect(CoachCard(p!, state: CardState.done).canUndo, isFalse);
    final (none, _) = propose('bajet_propose_bill_paid', {'bill': 'Netflix'}, withBill);
    expect(none.failed, isTrue);
  });

  test('a card reads as what it will do, then as what happened', () {
    final (_, p) = propose('bajet_propose_log', {'kind': 'income', 'amount_rm': 20, 'category': 'Refund'}, data);
    final card = CoachCard(p!);
    expect((card.outcome, card.action), ('Log this income?', 'Log it'));
    expect(card.copyWith(state: CardState.done, undoId: 9).canUndo, isTrue);
    expect(card.copyWith(state: CardState.declined).outcome, 'Not done');
  });
}
