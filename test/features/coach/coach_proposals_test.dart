import 'package:bajet/features/coach/domain/coach_lookups.dart';
import 'package:bajet/features/coach/domain/coach_proposals.dart';
import 'package:bajet/features/ledger/domain/ledger_models.dart';
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
    expect(log.rows, [('What', 'Lunch · Food'), ('Kind', 'Want'), ('From', 'Wallet'), ('Day', '15/10/2026')]);
    expect(log.effect, 'Counts toward your RM40.00 allowance.');
  });

  test("a spend takes the kind the coach gives, or else its category's, as the log sheet starts it", () {
    LogProposal log(String category, [String? kind]) =>
        propose('bajet_propose_log', {'kind': 'spending', 'amount_rm': 18, 'category': category, 'spend_kind': ?kind}, data).$2! as LogProposal;
    expect(log('Family').draft.spendKind, SpendKind.need);
    expect(log('Food').draft.spendKind, SpendKind.want);
    expect(log('Food', 'need').draft.spendKind, SpendKind.need);
    expect(log('Family', 'want').draft.spendKind, SpendKind.want);
    expect(log('Food', 'nonsense').draft.spendKind, SpendKind.want);
    expect(log('Family').effect, 'Stays out of your RM40.00 allowance.');
    expect(log('Family').rows, contains(('Kind', 'Need')));
  });

  test('only day-to-day spending says a kind', () {
    final (_, bill) = propose('bajet_propose_log', {'kind': 'spending', 'amount_rm': 50, 'category': 'Bills', 'spend_kind': 'need'}, data);
    final (_, income) = propose('bajet_propose_log', {'kind': 'income', 'amount_rm': 50, 'category': 'Refund', 'spend_kind': 'need'}, data);
    for (final p in [bill!, income!]) {
      expect(p.rows.map((r) => r.$1), isNot(contains('Kind')));
      expect(p.effect, isNull);
    }
    expect((bill as LogProposal).draft.spendKind, SpendKind.want);
  });

  test("a remembered card keeps its kind, and one saved before kinds still reads as a want", () {
    final (_, p) = propose('bajet_propose_log', {'kind': 'spending', 'amount_rm': 18, 'category': 'Family'}, data);
    final saved = cardToJson(CoachCard(p!));
    final back = cardFromJson(saved)!.proposal as LogProposal;
    expect((back.draft.spendKind, back.allowance), (SpendKind.need, 4000));
    final old = cardFromJson({...saved}..remove('spendKind')..remove('allowance'))!.proposal as LogProposal;
    expect((old.draft.spendKind, old.allowance, old.effect), (SpendKind.want, null, null));
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

  test('with no account named, a card uses the one last logged to, as the log sheet does', () {
    CoachData withEntries(List<Entry> entries) => CoachData(
          today: data.today,
          settings: data.settings,
          balance: data.balance,
          entries: entries,
          categories: data.categories,
          accounts: data.accounts,
          rules: data.rules,
          recurring: const [],
          projection: null,
          upcoming: const [],
        );
    int? used(List<Entry> entries) => (propose('bajet_propose_log', {'kind': 'spending', 'amount_rm': 5, 'category': 'Food'}, withEntries(entries)).$2! as LogProposal).draft.accountId;
    Entry entry(int id, DateTime day, int? account) => Entry(id: id, day: day, isIncome: false, amount: 100, categoryKey: 'food', accountId: account);

    expect(used([entry(1, d(10, 1), 1), entry(2, d(10, 9), 2)]), 2);
    expect(used([entry(2, d(10, 9), 2), entry(1, d(10, 1), 1)]), 2, reason: 'newest wins, in any order');
    expect(used(const []), 1, reason: 'nothing logged yet: the first account');
    expect(used([entry(1, d(10, 1), 99)]), 1, reason: 'that account has since gone');
  });

  test('the categories only the app logs to are not offered, as on the log sheet', () {
    for (final category in ['Goals', 'Untracked']) {
      final (r, p) = propose('bajet_propose_log', {'kind': 'spending', 'amount_rm': 5, 'category': category}, data);
      expect((r.failed, p), (true, null), reason: category);
      expect(r.text, isNot(contains(', Goals')));
    }
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

  test('a card for a bill, income or event settles it at the real amount', () {
    final rent = RecurringItem(id: 7, name: 'Rent', amount: 50000, categoryKey: 'bills', isIncome: false, nextDue: d(11, 1), accountId: 2);
    final pay = RecurringItem(id: 8, name: 'Pay', amount: 250000, categoryKey: 'salary', isIncome: true, nextDue: d(10, 15));
    final dinner = PlannedEvent(id: 3, name: 'Dinner', amount: 30000, categoryKey: 'gifts', isIncome: false, date: d(11, 20), spent: 12000);
    final withBill = CoachData(
      today: data.today,
      settings: data.settings,
      balance: data.balance,
      entries: data.entries,
      categories: data.categories,
      accounts: data.accounts,
      rules: data.rules,
      recurring: [rent, pay],
      projection: null,
      upcoming: const [],
      events: [dinner],
    );
    LogProposal card(Map<String, Object?> input) => propose('bajet_propose_log', {'kind': 'spending', ...input}, withBill).$2! as LogProposal;

    final paid = card({'for': 'rent', 'amount_rm': 492.4});
    expect((paid.draft.billId, paid.draft.amount, paid.draft.categoryKey, paid.draft.accountId, paid.draft.label), (7, 49240, 'bills', 2, 'Rent'));
    expect(paid.rows.take(2), [('Bill', 'Rent'), ('Planned', 'RM500.00')]);
    expect(paid.effect, 'Rent moves on to 01/12/2026.');
    expect((CoachCard(paid).outcome, CoachCard(paid).action), ('Pay this bill?', 'Pay it'));
    expect(CoachCard(paid, state: CardState.done).outcome, 'Paid');
    expect(card({'for': 'Rent'}).draft.amount, 50000, reason: 'no amount said: what is planned');

    final received = card({'for': 'Pay', 'amount_rm': 2480});
    expect((received.draft.isIncome, received.draft.billId, CoachCard(received).action), (true, 8, 'Received'));
    expect(CoachCard(received, state: CardState.done).outcome, 'Received');

    final spent = card({'for': 'dinner', 'amount_rm': 60, 'label': 'Cake', 'spend_kind': 'need'});
    expect((spent.draft.event, spent.draft.billId, spent.draft.categoryKey, spent.draft.label), (EventLink(3, d(11, 20)), null, 'gifts', 'Cake'));
    expect(spent.rows.take(2), [('For', 'Dinner'), ('Budget left', 'RM120.00 of RM300.00')]);
    expect(spent.rows.map((r) => r.$1), isNot(contains('Kind')));
    expect(spent.effect, 'Planned already, so it stays out of your allowance.');
    expect(card({'for': 'Dinner'}).draft.amount, 18000, reason: 'no amount said: what is left of its budget');

    final (none, nothing) = propose('bajet_propose_log', {'kind': 'spending', 'amount_rm': 5, 'for': 'Netflix'}, withBill);
    expect((none.failed, nothing), (true, null));
    expect(none.text, contains('They are: Rent, Pay, Dinner.'));

    final back = cardFromJson(cardToJson(CoachCard(paid)))!.proposal as LogProposal;
    expect((back.draft.billId, back.billDue, back.planned, back.effect), (7, d(11, 1), 50000, paid.effect));
    final backEvent = cardFromJson(cardToJson(CoachCard(spent)))!.proposal as LogProposal;
    expect((backEvent.draft.event, backEvent.spent, backEvent.rows[1]), (spent.draft.event, 12000, spent.rows[1]));
  });

  test('a saved card for income reads as received once done', () {
    final pay = RecurringItem(id: 8, name: 'Pay', amount: 250000, categoryKey: 'salary', isIncome: true, nextDue: d(10, 15));
    expect(CoachCard(BillPaidProposal(pay), state: CardState.done).outcome, 'Received');
  });

  test('the coach no longer offers a card that can only log the plan', () {
    expect(proposalTools.map((t) => t.name), isNot(contains('bajet_propose_bill_paid')));
    final (r, p) = propose('bajet_propose_bill_paid', {'bill': 'Rent'}, data);
    expect((r.failed, p), (true, null));
  });

  test('a card reads as what it will do, then as what happened', () {
    final (_, p) = propose('bajet_propose_log', {'kind': 'income', 'amount_rm': 20, 'category': 'Refund'}, data);
    final card = CoachCard(p!);
    expect((card.outcome, card.action), ('Log this income?', 'Log it'));
    expect(card.copyWith(state: CardState.done, undoId: 9).canUndo, isTrue);
    expect(card.copyWith(state: CardState.declined).outcome, 'Not done');
  });
}
