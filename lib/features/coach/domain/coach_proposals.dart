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

  /// A line under the rows saying what it does to the plan, if anything.
  String? get effect => null;
}

class LogProposal extends CoachProposal {
  const LogProposal(this.draft, this.categoryName, this.accountName, {this.allowance, this.billName, this.planned, this.billDue, this.eventName, this.budget, this.spent = 0});

  /// The row saying whether a spend is a want or a need.
  static const kindRow = 'Kind';

  final EntryDraft draft;
  final String categoryName;
  final String accountName;

  /// The weekly allowance, on a card for day-to-day spending, the only kind
  /// that is a want or a need; null on any other card.
  final int? allowance;

  /// The bill or income it settles, with its plan and the month it settles,
  /// so a card that waited is not tapped into paying a month twice.
  final String? billName;
  final int? planned;
  final DateTime? billDue;

  /// The planned event it is for; an expense's budget and what is already
  /// spent of it before this.
  final String? eventName;
  final int? budget;
  final int spent;

  @override
  String get question => switch ((billName, draft.isIncome)) {
        (_?, true) => 'Mark this received?',
        (_?, false) => 'Pay this bill?',
        (null, true) => 'Log this income?',
        (null, false) => 'Log this spend?',
      };
  @override
  int get amount => draft.amount;
  @override
  List<(String, String)> get rows => [
        if (billName != null) ...[
          (draft.isIncome ? 'Income' : 'Bill', billName!),
          if (planned != null) ('Planned', Money.format(planned!)),
        ] else if (eventName != null) ...[
          ('For', eventName!),
          if (budget != null) ('Budget left', '${Money.format((budget! - spent - draft.amount).clamp(0, budget!))} of ${Money.format(budget!)}'),
        ] else
          ('What', [if (draft.label != null) draft.label!, categoryName].join(' · ')),
        if (allowance != null) (kindRow, draft.spendKind == SpendKind.need ? 'Need' : 'Want'),
        (draft.isIncome ? 'Into' : 'From', accountName),
        ('Day', Dates.full(draft.day)),
      ];
  @override
  String? get effect {
    if (billDue case final due?) return '$billName moves on to ${Dates.full(DateTime.utc(due.year, due.month + 1, due.day))}.';
    if (budget != null) return 'Planned already, so it stays out of your allowance.';
    return switch (allowance) {
      null => null,
      final cap => draft.spendKind == SpendKind.need ? 'Stays out of your ${Money.format(cap)} allowance.' : 'Counts toward your ${Money.format(cap)} allowance.',
    };
  }
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

/// A bill marked paid at its planned amount. The coach no longer offers it,
/// since a log card for the bill carries the real amount; it stays so cards
/// already in a remembered chat still work.
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

/// Where a card stands. [outdated] is a card that would no longer do what it
/// said, because the same change was made somewhere else first.
enum CardState { waiting, done, declined, undone, outdated }

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
        LogProposal(:final draft) => draft.billId == null ? 'Log it' : (draft.isIncome ? 'Received' : 'Pay it'),
        MoveProposal() => 'Move it',
        BillPaidProposal(:final item) => item.isIncome ? 'Received' : 'Mark paid',
      };

  String get outcome => switch (state) {
        CardState.waiting => proposal.question,
        CardState.done => switch (proposal) { LogProposal(:final draft) => draft.billId == null ? 'Logged' : (draft.isIncome ? 'Received' : 'Paid'), MoveProposal() => 'Moved', BillPaidProposal() => 'Marked paid' },
        CardState.declined => 'Not done',
        CardState.undone => 'Undone, nothing changed',
        CardState.outdated => 'Already changed elsewhere, nothing done',
      };

  CoachCard copyWith({required CardState state, int? undoId}) => CoachCard(proposal, state: state, undoId: undoId ?? this.undoId);
}

/// A card as JSON, to be remembered with its message.
Map<String, Object?> cardToJson(CoachCard c) => {
      'state': c.state.name,
      if (c.undoId != null) 'undoId': c.undoId,
      ...switch (c.proposal) {
        LogProposal(:final draft, :final categoryName, :final accountName, :final allowance, :final billName, :final planned, :final billDue, :final eventName, :final budget, :final spent) => {
            'kind': 'log',
            'day': _iso(draft.day),
            'income': draft.isIncome,
            'amount': draft.amount,
            'category': draft.categoryKey,
            'label': draft.label,
            'account': draft.accountId,
            'categoryName': categoryName,
            'accountName': accountName,
            'spendKind': draft.spendKind.name,
            'allowance': ?allowance,
            'billId': ?draft.billId,
            'billName': ?billName,
            'planned': ?planned,
            if (billDue != null) 'billDue': _iso(billDue),
            if (draft.event case final link?) ...{'eventId': link.eventId, 'eventOn': _iso(link.on)},
            'eventName': ?eventName,
            'budget': ?budget,
            if (spent != 0) 'spent': spent,
          },
        MoveProposal(:final fromId, :final toId, :final fromName, :final toName, :final amount, :final day, :final note) => {
            'kind': 'move',
            'from': fromId,
            'to': toId,
            'fromName': fromName,
            'toName': toName,
            'amount': amount,
            'day': _iso(day),
            'note': note,
          },
        BillPaidProposal(:final item) => {
            'kind': 'bill',
            'id': item.id,
            'name': item.name,
            'amount': item.amount,
            'category': item.categoryKey,
            'income': item.isIncome,
            'due': _iso(item.nextDue),
          },
      },
    };

/// A remembered card, or null if it cannot be read, which drops just that
/// card rather than the chat.
CoachCard? cardFromJson(Map<String, Object?> j) {
  try {
    final state = CardState.values.byName(j['state']! as String);
    final CoachProposal p = switch (j['kind']) {
      'log' => LogProposal(
          EntryDraft(
            day: _day(j['day']! as String)!,
            isIncome: j['income']! as bool,
            amount: j['amount']! as int,
            categoryKey: j['category']! as String,
            label: j['label'] as String?,
            accountId: j['account'] as int?,
            // Cards saved before spends had a kind always logged wants.
            spendKind: SpendKind.values.asNameMap()[j['spendKind']] ?? SpendKind.want,
            billId: j['billId'] as int?,
            event: j['eventId'] == null ? null : EventLink(j['eventId']! as int, _day(j['eventOn']! as String)!),
          ),
          j['categoryName']! as String,
          j['accountName']! as String,
          allowance: j['allowance'] as int?,
          billName: j['billName'] as String?,
          planned: j['planned'] as int?,
          billDue: j['billDue'] == null ? null : _day(j['billDue']! as String),
          eventName: j['eventName'] as String?,
          budget: j['budget'] as int?,
          spent: j['spent'] as int? ?? 0,
        ),
      'move' => MoveProposal(
          fromId: j['from']! as int,
          toId: j['to']! as int,
          fromName: j['fromName']! as String,
          toName: j['toName']! as String,
          amount: j['amount']! as int,
          day: _day(j['day']! as String)!,
          note: j['note'] as String?,
        ),
      'bill' => BillPaidProposal(RecurringItem(
          id: j['id']! as int,
          name: j['name']! as String,
          amount: j['amount']! as int,
          categoryKey: j['category']! as String,
          isIncome: j['income']! as bool,
          nextDue: _day(j['due']! as String)!,
        )),
      _ => throw const FormatException('unknown card'),
    };
    return CoachCard(p, state: state, undoId: j['undoId'] as int?);
  } on Object {
    return null;
  }
}

String _iso(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// The largest single amount the coach may suggest, so a slip of the model
/// ("RM50,000" for "RM50") never even reaches a card.
const proposalLimit = 10000000;

const proposalTools = [
  CoachLookup(
    'bajet_propose_log',
    'Suggests logging one spend or income for the user to confirm. It does not log anything: the app shows the user a card with '
        'Log it and Not now, and only their tap writes it. Use it when the user asks you to log, record or add something. Give the '
        'amount in ringgit, the category by its name, and the account by its name if they said one. A day-to-day spend is a want or a '
        'need, and only wants count toward the weekly allowance, so say which when you can tell. When it pays a monthly bill, receives '
        'monthly income or goes on a planned event, name that in for, with the real amount if they said one: only then does the plan '
        'know it is settled, and Runway stops counting it.',
    {
      'type': 'object',
      'properties': {
        'kind': {'type': 'string', 'enum': ['spending', 'income']},
        'amount_rm': {'type': 'number', 'description': 'The amount in ringgit, such as 12.5 for RM12.50. May be left out only with for, to use what is planned.'},
        'category': {'type': 'string', 'description': 'An existing category name, such as Food. Leave out with for.'},
        'for': {'type': 'string', 'description': 'The monthly bill, monthly income or planned event this settles or is spent on, named as bajet_plan lists it.'},
        'label': {'type': 'string', 'description': 'A short label, such as Lunch.'},
        'spend_kind': {
          'type': 'string',
          'enum': ['want', 'need'],
          'description': 'For a spend: need if it would be bought anyway or was asked for, want if the user chose it and could have skipped it or waited without harm. '
              "Leave out when unsure, for the category's usual kind.",
        },
        'account': {'type': 'string', 'description': 'The account name; leave out for the first account.'},
        'day': {'type': 'string', 'description': 'The day as yyyy-mm-dd; leave out for today.'},
      },
      'required': ['kind'],
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
      final wantedFor = text('for')?.toLowerCase();
      final bill = d.recurring.where((r) => r.active && r.name.toLowerCase() == wantedFor).firstOrNull;
      final event = bill != null ? null : d.events.where((e) => !e.done && e.name.toLowerCase() == wantedFor).firstOrNull;
      if (wantedFor != null && bill == null && event == null) {
        final names = [for (final r in d.recurring) if (r.active) r.name, for (final e in d.events) if (!e.done) e.name].join(', ');
        return (no('there is no bill, income or planned event called "${text('for')}". They are: $names.'), null);
      }
      final income = bill?.isIncome ?? event?.isIncome ?? input['kind'] == 'income';
      // What is planned, when the user gave no amount for what it settles.
      final expected = bill?.amount ?? event?.outstanding ?? 0;
      final sen = input.containsKey('amount_rm') || expected == 0 ? amount() : expected;
      if (sen == null) return (no('the amount must be more than RM0.00 and at most ${Money.format(proposalLimit)}.'), null);
      // As the log sheet: a bill or event brings its own category.
      final wantedCategory = text('category')?.toLowerCase();
      final categoryKey = bill?.categoryKey ?? event?.categoryKey;
      final category = d.categories.where((c) => categoryKey != null ? c.key == categoryKey : c.isIncome == income && c.label.toLowerCase() == wantedCategory).firstOrNull;
      if (category == null) {
        final names = d.categories.where((c) => c.isIncome == income).map((c) => c.label).join(', ');
        return (no('there is no ${income ? 'income' : 'spending'} category called "${text('category') ?? categoryKey}". The categories are: $names.'), null);
      }
      final accountId = text('account') == null ? bill?.accountId ?? account(null) : account(text('account'));
      if (accountId == null) return (no('there is no account called "${text('account')}". The accounts are: $accountsList.'), null);
      final dayText = text('day');
      final day = dayText == null ? d.today : _day(dayText);
      if (day == null || day.isAfter(d.today) || day.isBefore(DateTime.utc(d.today.year - 1, d.today.month, d.today.day))) {
        return (no('the day must be yyyy-mm-dd, no later than today and within the last year.'), null);
      }
      // As the log sheet: a spend starts as its category's kind, and only
      // day-to-day spending asks.
      final dayToDay = !income && !category.isFixed && bill == null && event == null;
      final kind = (dayToDay ? SpendKind.values.asNameMap()[input['spend_kind']] : null) ?? category.spendKind;
      final draft = EntryDraft(
        day: day,
        isIncome: income,
        amount: sen,
        categoryKey: category.key,
        label: bill?.name ?? (event?.isIncome == true ? event!.name : text('label')),
        accountId: accountId,
        spendKind: kind,
        billId: bill?.id,
        event: event == null ? null : EventLink(event.id, event.date),
      );
      final p = LogProposal(
        draft,
        category.label,
        called(accountId),
        allowance: dayToDay ? d.settings.weeklyCap : null,
        billName: bill?.name,
        planned: bill?.amount,
        billDue: bill?.nextDue,
        eventName: event?.name,
        budget: event != null && !event.isIncome ? event.amount : null,
        spent: event?.spent ?? 0,
      );
      final asKind = dayToDay ? ', as a ${kind.name}' : '';
      return (LookupResult('Shown to the user as a card to confirm: ${p.question} ${Money.format(sen)}$asKind. Nothing is logged unless they tap ${CoachCard(p).action}.', 'A suggestion'), p);
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
