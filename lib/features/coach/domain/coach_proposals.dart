import '../../../core/dates/dates.dart';
import '../../../core/money/money.dart';
import '../../ledger/domain/ledger_models.dart';
import '../../plan/domain/plan_models.dart';
import 'coach_lookups.dart';

/// A change the coach may only suggest. The app checks it, shows it as a
/// card, and does nothing until the user taps.
sealed class CoachProposal {
  const CoachProposal();

  /// The card's heading, such as "Log this spend?".
  String get question;

  /// The amount in large type, then label and value rows.
  int get amount;
  List<(String, String)> get rows;
}

class LogProposal extends CoachProposal {
  const LogProposal(this.draft, this.categoryName, this.accountName);

  final EntryDraft draft;
  final String categoryName;
  final String accountName;

  @override
  String get question => draft.isIncome ? 'Log this income?' : 'Log this spend?';
  @override
  int get amount => draft.amount;
  @override
  List<(String, String)> get rows => [
        ('What', [if (draft.label != null) draft.label!, categoryName].join(' · ')),
        (draft.isIncome ? 'Into' : 'From', accountName),
        ('Day', Dates.full(draft.day)),
      ];
}

class MoveProposal extends CoachProposal {
  const MoveProposal({required this.fromId, required this.toId, required this.fromName, required this.toName, required this.amount, required this.day, this.note});

  final int fromId, toId;
  final String fromName, toName;
  @override
  final int amount;
  final DateTime day;
  final String? note;

  @override
  String get question => 'Move this money?';
  @override
  List<(String, String)> get rows => [('From', fromName), ('To', toName), ('Day', Dates.full(day))];
}

class BillPaidProposal extends CoachProposal {
  const BillPaidProposal(this.item);

  final RecurringItem item;

  @override
  String get question => item.isIncome ? 'Mark this received?' : 'Mark this bill paid?';
  @override
  int get amount => item.amount;
  @override
  List<(String, String)> get rows => [('Bill', item.name), ('Was due', Dates.full(item.nextDue))];
}

enum CardState { waiting, done, declined, undone }

/// A proposal shown in the chat, and what the user did with it.
class CoachCard {
  const CoachCard(this.proposal, {this.state = CardState.waiting, this.undoId});

  final CoachProposal proposal;
  final CardState state;

  /// The entry or transfer the tap created, so Undo can remove it.
  final int? undoId;

  /// Marking a bill paid moves it to next month too, so like the Paid button
  /// on Today it has no Undo.
  bool get canUndo => state == CardState.done && undoId != null;

  String get action => switch (proposal) {
        LogProposal() => 'Log it',
        MoveProposal() => 'Move it',
        BillPaidProposal(:final item) => item.isIncome ? 'Received' : 'Mark paid',
      };

  String get outcome => switch (state) {
        CardState.waiting => proposal.question,
        CardState.done => switch (proposal) { LogProposal() => 'Logged', MoveProposal() => 'Moved', BillPaidProposal() => 'Marked paid' },
        CardState.declined => 'Not done',
        CardState.undone => 'Undone, nothing changed',
      };

  CoachCard copyWith({required CardState state, int? undoId}) => CoachCard(proposal, state: state, undoId: undoId ?? this.undoId);
}

/// The largest single amount the coach may suggest, so a slip of the model
/// ("RM50,000" for "RM50") never even reaches a card.
const proposalLimit = 10000000;

const proposalTools = [
  CoachLookup(
    'bajet_propose_log',
    'Suggests logging one spend or income for the user to confirm. It does not log anything: the app shows the user a card with '
        'Log it and Not now, and only their tap writes it. Use it when the user asks you to log, record or add something. Give the '
        'amount in ringgit, the category by its name, and the account by its name if they said one.',
    {
      'type': 'object',
      'properties': {
        'kind': {'type': 'string', 'enum': ['spending', 'income']},
        'amount_rm': {'type': 'number', 'description': 'The amount in ringgit, such as 12.5 for RM12.50.'},
        'category': {'type': 'string', 'description': 'An existing category name, such as Food.'},
        'label': {'type': 'string', 'description': 'A short label, such as Lunch.'},
        'account': {'type': 'string', 'description': 'The account name; leave out for the first account.'},
        'day': {'type': 'string', 'description': 'The day as yyyy-mm-dd; leave out for today.'},
      },
      'required': ['kind', 'amount_rm', 'category'],
    },
  ),
  CoachLookup(
    'bajet_propose_move',
    'Suggests moving money between two of the user\'s own accounts, such as topping up an e-wallet from the bank, for them to '
        'confirm. It moves nothing itself: the app shows a card and only the user\'s tap does it. A move is not spending or income.',
    {
      'type': 'object',
      'properties': {
        'amount_rm': {'type': 'number', 'description': 'The amount in ringgit.'},
        'from': {'type': 'string', 'description': 'The account the money leaves, by name.'},
        'to': {'type': 'string', 'description': 'The account it goes to, by name.'},
        'note': {'type': 'string'},
      },
      'required': ['amount_rm', 'from', 'to'],
    },
  ),
  CoachLookup(
    'bajet_propose_bill_paid',
    'Suggests marking one monthly bill as paid, or one income as received, for the user to confirm; this logs it and moves it to '
        'next month. It does nothing itself: the app shows a card and only the user\'s tap does it. Name the bill as bajet_plan lists it.',
    {
      'type': 'object',
      'properties': {
        'bill': {'type': 'string', 'description': 'The bill or income name.'},
      },
      'required': ['bill'],
    },
  ),
];

/// Checks the proposal [name] asks for against [d]. Returns what to tell
/// the model, and the proposal when it can become a card.
(LookupResult, CoachProposal?) propose(String name, Map<String, Object?> input, CoachData d) {
  LookupResult no(String why) => LookupResult('Not shown to the user: $why', 'A suggestion', failed: true);
  String? text(String key) {
    final v = input[key];
    return v is String && v.trim().isNotEmpty ? v.trim() : null;
  }

  int? amount() {
    final v = input['amount_rm'];
    final sen = v is num ? (v * 100).round() : (v is String ? ((double.tryParse(v) ?? 0) * 100).round() : 0);
    return sen > 0 && sen <= proposalLimit ? sen : null;
  }

  int? account(String? wanted) {
    if (d.accounts.isEmpty) return null;
    if (wanted == null) return d.accounts.first.id;
    for (final a in d.accounts) {
      if (a.called.toLowerCase() == wanted.toLowerCase() || a.name.toLowerCase() == wanted.toLowerCase()) return a.id;
    }
    return null;
  }

  String called(int id) => d.accounts.firstWhere((a) => a.id == id).called;
  final accountsList = d.accounts.map((a) => a.called).join(', ');

  switch (name) {
    case 'bajet_propose_log':
      final income = input['kind'] == 'income';
      final sen = amount();
      if (sen == null) return (no('the amount must be more than RM0.00 and at most ${Money.format(proposalLimit)}.'), null);
      final wantedCategory = text('category')?.toLowerCase();
      final category = d.categories.where((c) => c.isIncome == income && c.label.toLowerCase() == wantedCategory).firstOrNull;
      if (category == null) {
        final names = d.categories.where((c) => c.isIncome == income).map((c) => c.label).join(', ');
        return (no('there is no ${income ? 'income' : 'spending'} category called "${text('category')}". The categories are: $names.'), null);
      }
      final accountId = account(text('account'));
      if (accountId == null) return (no('there is no account called "${text('account')}". The accounts are: $accountsList.'), null);
      final dayText = text('day');
      final day = dayText == null ? d.today : _day(dayText);
      if (day == null || day.isAfter(d.today) || day.isBefore(DateTime.utc(d.today.year - 1, d.today.month, d.today.day))) {
        return (no('the day must be yyyy-mm-dd, no later than today and within the last year.'), null);
      }
      final draft = EntryDraft(day: day, isIncome: income, amount: sen, categoryKey: category.key, label: text('label'), accountId: accountId);
      final p = LogProposal(draft, category.label, called(accountId));
      return (LookupResult('Shown to the user as a card to confirm: ${p.question} ${Money.format(sen)}. Nothing is logged unless they tap Log it.', 'A suggestion'), p);
    case 'bajet_propose_move':
      final sen = amount();
      if (sen == null) return (no('the amount must be more than RM0.00 and at most ${Money.format(proposalLimit)}.'), null);
      final from = account(text('from') ?? ''), to = account(text('to') ?? '');
      if (from == null || to == null) return (no('both accounts must be named exactly. The accounts are: $accountsList.'), null);
      if (from == to) return (no('the two accounts must differ.'), null);
      // Accounts may go negative when the user moves money by hand, but the
      // coach never suggests moving more than is there.
      final holds = d.accounts.firstWhere((a) => a.id == from).balance;
      if (sen > holds) return (no('${called(from)} only holds ${Money.format(holds)}; the user can move more by hand.'), null);
      final p = MoveProposal(fromId: from, toId: to, fromName: called(from), toName: called(to), amount: sen, day: d.today, note: text('note'));
      return (LookupResult('Shown to the user as a card to confirm: move ${Money.format(sen)} from ${p.fromName} to ${p.toName}. Nothing moves unless they tap.', 'A suggestion'), p);
    case 'bajet_propose_bill_paid':
      final wanted = text('bill')?.toLowerCase();
      final item = d.recurring.where((r) => r.active && r.name.toLowerCase() == wanted).firstOrNull;
      if (item == null) {
        return (no('there is no active bill or income called "${text('bill')}". They are: ${d.recurring.where((r) => r.active).map((r) => r.name).join(', ')}.'), null);
      }
      final p = BillPaidProposal(item);
      return (LookupResult('Shown to the user as a card to confirm: ${p.question} ${item.name}. Nothing changes unless they tap.', 'A suggestion'), p);
    default:
      return (no('there is no suggestion called $name.'), null);
  }
}

DateTime? _day(String v) {
  final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(v);
  if (m == null) return null;
  final day = DateTime.utc(int.parse(m[1]!), int.parse(m[2]!), int.parse(m[3]!));
  return day.month == int.parse(m[2]!) ? day : null;
}
