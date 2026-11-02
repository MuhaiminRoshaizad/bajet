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
  static const kindRow = 'Whose call';

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

  /// The same card once the user has changed [saved] on the log sheet: what
  /// it shows follows what they kept.
  LogProposal changedTo(EntryDraft saved, {required String categoryName, required String accountName, required int? allowance}) => LogProposal(
        saved,
        categoryName,
        accountName,
        allowance: allowance,
        billName: saved.billId == draft.billId ? billName : null,
        planned: saved.billId == draft.billId ? planned : null,
        billDue: saved.billId == draft.billId ? billDue : null,
        eventName: saved.event == draft.event ? eventName : null,
        budget: saved.event == draft.event ? budget : null,
        spent: saved.event == draft.event ? spent : 0,
      );

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
        if (allowance != null) (kindRow, draft.spendKind.label),
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

/// A change to an entry already logged, such as a spend that was a need.
/// Links to a bill or event stay as they are.
class ChangeProposal extends CoachProposal {
  const ChangeProposal({
    required this.before,
    required this.after,
    required this.beforeCategory,
    required this.afterCategory,
    required this.beforeAccount,
    required this.afterAccount,
    this.allowance,
    this.wantBefore = false,
    this.wantAfter = false,
  });

  final Entry before, after;
  final String beforeCategory, afterCategory, beforeAccount, afterAccount;

  /// The weekly allowance, when a kind row is shown, with whether the entry
  /// counted toward it before and would after.
  final int? allowance;
  final bool wantBefore, wantAfter;

  @override
  String get question => 'Change this entry?';
  @override
  int get amount => after.amount;
  @override
  List<(String, String)> get rows => [
        ('Entry', '${before.label ?? beforeCategory} · ${Dates.full(before.day)}'),
        if (after.amount != before.amount) ('Amount', '${Money.format(before.amount)} → ${Money.format(after.amount)}'),
        if (afterCategory != beforeCategory) ('Category', '$beforeCategory → $afterCategory'),
        if (after.label != before.label) ('Label', '${before.label ?? 'none'} → ${after.label ?? 'none'}'),
        if (after.day != before.day) ('Day', '${Dates.full(before.day)} → ${Dates.full(after.day)}'),
        if (afterAccount != beforeAccount) (after.isIncome ? 'Into' : 'From', '$beforeAccount → $afterAccount'),
        if (allowance != null && after.spendKind != before.spendKind) (LogProposal.kindRow, '${before.spendKind.label} → ${after.spendKind.label}'),
      ];
  @override
  String? get effect {
    final change = (wantAfter ? after.amount : 0) - (wantBefore ? before.amount : 0);
    if (allowance == null || change == 0) return null;
    return change < 0 ? "Gives ${Money.format(-change)} back to that week's allowance." : "Takes ${Money.format(change)} more from that week's allowance.";
  }
}

/// A planned event to add, with what it does to Runway.
class EventProposal extends CoachProposal {
  const EventProposal({
    required this.name,
    required this.amount,
    required this.isIncome,
    required this.categoryKey,
    required this.categoryName,
    required this.date,
    this.yearly = false,
    this.counted = true,
    this.runway,
  });

  final String name;
  @override
  final int amount;
  final bool isIncome;
  final String categoryKey, categoryName;
  final DateTime date;
  final bool yearly, counted;

  /// What Runway expects with it against without it, worked out when the
  /// card was made.
  final String? runway;

  @override
  String get question => 'Add this planned event?';
  @override
  List<(String, String)> get rows => [
        ('What', '$name · $categoryName'),
        ('On', Dates.full(date)),
        if (yearly) ('Repeats', 'Every year'),
        ('Runway', counted ? 'Counts it' : 'Leaves it out'),
      ];
  @override
  String? get effect => runway;
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

  /// Undo takes back the entry, and with it whatever the entry settled.
  bool get canUndo => state == CardState.done && undoId != null;

  String get action => switch (proposal) {
        LogProposal(:final draft) => draft.billId == null ? 'Log it' : (draft.isIncome ? 'Received' : 'Pay it'),
        MoveProposal() => 'Move it',
        BillPaidProposal(:final item) => item.isIncome ? 'Received' : 'Mark paid',
        ChangeProposal() => 'Change it',
        EventProposal() => 'Add it',
      };

  String get outcome => switch (state) {
        CardState.waiting => proposal.question,
        CardState.done => switch (proposal) { LogProposal(:final draft) => draft.billId == null ? 'Logged' : (draft.isIncome ? 'Received' : 'Paid'), MoveProposal() => 'Moved', BillPaidProposal(:final item) => item.isIncome ? 'Received' : 'Marked paid', ChangeProposal() => 'Changed', EventProposal() => 'Added' },
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
        EventProposal() && final p => {
            'kind': 'event',
            'name': p.name,
            'amount': p.amount,
            'income': p.isIncome,
            'category': p.categoryKey,
            'categoryName': p.categoryName,
            'day': _iso(p.date),
            'yearly': p.yearly,
            'counted': p.counted,
            'runway': ?p.runway,
          },
        ChangeProposal() && final p => {
            'kind': 'change',
            'before': _entryToJson(p.before),
            'after': _entryToJson(p.after),
            'beforeCategory': p.beforeCategory,
            'afterCategory': p.afterCategory,
            'beforeAccount': p.beforeAccount,
            'afterAccount': p.afterAccount,
            'allowance': ?p.allowance,
            'wantBefore': p.wantBefore,
            'wantAfter': p.wantAfter,
          },
      },
    };

Map<String, Object?> _entryToJson(Entry e) => {
      'id': e.id,
      'day': _iso(e.day),
      'income': e.isIncome,
      'amount': e.amount,
      'category': e.categoryKey,
      'label': e.label,
      'note': e.note,
      'receipt': e.receipt,
      'account': e.accountId,
      'billId': e.billId,
      if (e.event case final link?) ...{'eventId': link.eventId, 'eventOn': _iso(link.on)},
      'spendKind': e.spendKind.name,
    };

Entry _entryFromJson(Map<String, Object?> j) => Entry(
      id: j['id']! as int,
      day: _day(j['day']! as String)!,
      isIncome: j['income']! as bool,
      amount: j['amount']! as int,
      categoryKey: j['category']! as String,
      label: j['label'] as String?,
      note: j['note'] as String?,
      receipt: j['receipt'] as String?,
      accountId: j['account'] as int?,
      billId: j['billId'] as int?,
      event: j['eventId'] == null ? null : EventLink(j['eventId']! as int, _day(j['eventOn']! as String)!),
      spendKind: SpendKind.values.byName(j['spendKind']! as String),
    );

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
      'event' => EventProposal(
          name: j['name']! as String,
          amount: j['amount']! as int,
          isIncome: j['income']! as bool,
          categoryKey: j['category']! as String,
          categoryName: j['categoryName']! as String,
          date: _day(j['day']! as String)!,
          yearly: j['yearly'] as bool? ?? false,
          counted: j['counted'] as bool? ?? true,
          runway: j['runway'] as String?,
        ),
      'change' => ChangeProposal(
          before: _entryFromJson((j['before']! as Map).cast()),
          after: _entryFromJson((j['after']! as Map).cast()),
          beforeCategory: j['beforeCategory']! as String,
          afterCategory: j['afterCategory']! as String,
          beforeAccount: j['beforeAccount']! as String,
          afterAccount: j['afterAccount']! as String,
          allowance: j['allowance'] as int?,
          wantBefore: j['wantBefore'] as bool? ?? false,
          wantAfter: j['wantAfter'] as bool? ?? false,
        ),
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
    'bajet_propose_event',
    'Suggests adding a planned event, a one-off or yearly cost or income such as a birthday dinner or a bonus, for the user to '
        'confirm. It adds nothing itself: the app shows a card with what it does to Runway, and only the user\'s tap adds it, with Undo. '
        'Use it when the user wants something coming up in their plan. Something monthly is a bill, which they add by hand.',
    {
      'type': 'object',
      'properties': {
        'name': {'type': 'string', 'description': 'A short name, such as Birthday dinner.'},
        'kind': {'type': 'string', 'enum': ['spending', 'income']},
        'amount_rm': {'type': 'number', 'description': 'The amount in ringgit; for spending, its budget.'},
        'category': {'type': 'string', 'description': 'An existing category name.'},
        'day': {'type': 'string', 'description': 'The day as yyyy-mm-dd, today or later.'},
        'yearly': {'type': 'boolean', 'description': 'True when it comes back on the same day every year.'},
        'counted': {'type': 'boolean', 'description': 'False for money that may not come, such as an unconfirmed bonus. True if left out.'},
      },
      'required': ['name', 'kind', 'amount_rm', 'category', 'day'],
    },
  ),
  CoachLookup(
    'bajet_propose_change',
    'Suggests changing one entry already logged, for the user to confirm: whose call it was, amount, category, label, day or '
        'account. It changes nothing itself: the app shows a card with the change and only the user\'s tap makes it, with Undo. Use it '
        'when the user says an entry is wrong, such as "that one was not my call actually". Find the entry\'s id with bajet_entries. Give only '
        'what changes. A bill or event an entry settles stays as it is.',
    {
      'type': 'object',
      'properties': {
        'entry_id': {'type': 'integer', 'description': 'The id bajet_entries gives the entry.'},
        'spend_kind': {'type': 'string', 'enum': ['my_call', 'not_my_call'], 'description': 'For day-to-day spending only.'},
        'amount_rm': {'type': 'number', 'description': 'The new amount in ringgit.'},
        'category': {'type': 'string', 'description': 'The new category, by its name.'},
        'label': {'type': 'string', 'description': 'The new label.'},
        'day': {'type': 'string', 'description': 'The new day as yyyy-mm-dd.'},
        'account': {'type': 'string', 'description': 'The new account, by its name.'},
      },
      'required': ['entry_id'],
    },
  ),
  CoachLookup(
    'bajet_propose_log',
    'Suggests logging one spend or income for the user to confirm. It does not log anything: the app shows the user a card with '
        'Log it and Not now, and only their tap writes it. Use it when the user asks you to log, record or add something. Give the '
        'amount in ringgit, the category by its name, and the account by its name if they said one. A day-to-day spend is my call or '
        'not my call, and only my calls count toward the weekly allowance, so say which when you can tell. When it pays a monthly bill, receives '
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
          'enum': ['my_call', 'not_my_call'],
          'description': 'For a spend: not_my_call if the user had no real say in it, my_call if they decided and could have skipped it or waited without harm. '
              "Leave out when unsure, for the category's usual kind.",
        },
        'account': {'type': 'string', 'description': 'The account name; leave out for the one the user last logged to.'},
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
    // As the log sheet: most money goes where the last of it went.
    if (wanted == null) {
      final last = d.entries.isEmpty ? null : d.entries.reduce((a, b) => a.day.compareTo(b.day) != 0 ? (a.day.isAfter(b.day) ? a : b) : (a.id > b.id ? a : b)).accountId;
      return d.accounts.any((a) => a.id == last) ? last : d.accounts.first.id;
    }
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
      final category = d.categories.where((c) => categoryKey != null ? c.key == categoryKey : c.isIncome == income && !c.isAutomatic && c.label.toLowerCase() == wantedCategory).firstOrNull;
      if (category == null) {
        final names = d.categories.where((c) => c.isIncome == income && !c.isAutomatic).map((c) => c.label).join(', ');
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
      final kind = (dayToDay ? SpendKind.fromTool(input['spend_kind']) : null) ?? category.spendKind;
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
      final asKind = dayToDay ? ', as ${kind.words}' : '';
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
    case 'bajet_propose_event':
      final eventName = text('name');
      if (eventName == null || eventName.length > 40) return (no('give a name of at most 40 characters.'), null);
      if (d.events.any((e) => !e.done && e.name.toLowerCase() == eventName.toLowerCase())) {
        return (no('there is already a planned event called "$eventName".'), null);
      }
      final income = input['kind'] == 'income';
      final sen = amount();
      if (sen == null) return (no('the amount must be more than RM0.00 and at most ${Money.format(proposalLimit)}.'), null);
      final wanted = text('category')?.toLowerCase();
      final category = d.categories.where((c) => c.isIncome == income && !c.isAutomatic && c.label.toLowerCase() == wanted).firstOrNull;
      if (category == null) {
        final names = d.categories.where((c) => c.isIncome == income && !c.isAutomatic).map((c) => c.label).join(', ');
        return (no('there is no such category. The categories are: $names.'), null);
      }
      final day = _day(text('day') ?? '');
      if (day == null || day.isBefore(d.today) || day.isAfter(DateTime.utc(d.today.year + 3, d.today.month, d.today.day))) {
        return (no('the day must be yyyy-mm-dd, from today to three years ahead.'), null);
      }
      final counted = input['counted'] != false;
      final event = PlannedEvent(id: -1, name: eventName, amount: sen, categoryKey: category.key, isIncome: income, date: day, repeatsYearly: input['yearly'] == true);
      final p = EventProposal(
        name: eventName,
        amount: sen,
        isIncome: income,
        categoryKey: category.key,
        categoryName: category.label,
        date: day,
        yearly: event.repeatsYearly,
        counted: counted,
        runway: counted ? _runwayLine(d, event) : 'Runway leaves it out until it is counted.',
      );
      return (LookupResult('Shown to the user as a card to confirm: ${p.question} ${p.effect} Nothing is added unless they tap Add it.', 'A suggestion'), p);
    case 'bajet_propose_change':
      final id = input['entry_id'];
      final before = d.entries.where((e) => e.id == (id is num ? id.toInt() : int.tryParse('$id'))).firstOrNull;
      if (before == null) return (no('there is no entry with id $id. Find it with bajet_entries.'), null);
      final fixed = {for (final c in d.categories) if (c.isFixed) c.key};
      final wantedCategory = text('category')?.toLowerCase();
      final category = wantedCategory == null
          ? null
          : d.categories.where((c) => c.isIncome == before.isIncome && !c.isAutomatic && c.label.toLowerCase() == wantedCategory).firstOrNull;
      if (wantedCategory != null && category == null) {
        final names = d.categories.where((c) => c.isIncome == before.isIncome && !c.isAutomatic).map((c) => c.label).join(', ');
        return (no('there is no such category. The categories are: $names.'), null);
      }
      final sen = input.containsKey('amount_rm') ? amount() : before.amount;
      if (sen == null) return (no('the amount must be more than RM0.00 and at most ${Money.format(proposalLimit)}.'), null);
      final dayText = text('day');
      final day = dayText == null ? before.day : _day(dayText);
      if (day == null || day.isAfter(d.today)) return (no('the day must be yyyy-mm-dd and no later than today.'), null);
      final accountId = text('account') == null ? before.accountId : account(text('account'));
      if (text('account') != null && accountId == null) return (no('there is no account called "${text('account')}". The accounts are: $accountsList.'), null);
      final categoryKey = category?.key ?? before.categoryKey;
      final askedKind = SpendKind.fromTool(input['spend_kind']);
      final dayToDay = !before.isIncome && !fixed.contains(categoryKey) && before.billId == null && before.event == null;
      if (askedKind != null && !dayToDay) return (no('only day-to-day spending is my call or not my call; this entry is planned or income.'), null);
      final after = Entry(
        id: before.id,
        day: day,
        isIncome: before.isIncome,
        amount: sen,
        categoryKey: categoryKey,
        label: text('label') ?? before.label,
        note: before.note,
        receipt: before.receipt,
        event: before.event,
        accountId: accountId,
        billId: before.billId,
        spendKind: askedKind ?? (category != null ? category.spendKind : before.spendKind),
      );
      String categoryOf(String key) => d.categories.where((c) => c.key == key).firstOrNull?.label ?? key;
      String accountOf(int? id) => d.accounts.where((a) => a.id == (id ?? d.accounts.first.id)).firstOrNull?.called ?? 'an account';
      final p = ChangeProposal(
        before: before,
        after: after,
        beforeCategory: categoryOf(before.categoryKey),
        afterCategory: categoryOf(after.categoryKey),
        beforeAccount: accountOf(before.accountId),
        afterAccount: accountOf(after.accountId),
        allowance: dayToDay ? d.settings.weeklyCap : null,
        wantBefore: before.isWant(fixed),
        wantAfter: after.isWant(fixed),
      );
      if (p.rows.length == 1) return (no('nothing about the entry would change.'), null);
      return (LookupResult('Shown to the user as a card to confirm: ${p.question} Nothing changes unless they tap Change it.', 'A suggestion'), p);
    default:
      return (no('there is no suggestion called $name.'), null);
  }
}

/// What adding [event] does to Runway, in one line.
String _runwayLine(CoachData d, PlannedEvent event) {
  final before = runway(d), after = runway(d, extra: [event]);
  if (after.goals.isNotEmpty && before.goals.isNotEmpty) {
    final goal = after.goals.first;
    return 'After buying ${goal.goal.name}: ${Money.format(goal.leftAfterBuying)} left, was ${Money.format(before.goals.first.leftAfterBuying)}.';
  }
  return 'On ${Dates.full(after.days.last.date)}: ${Money.format(after.days.last.balance)}, was ${Money.format(before.days.last.balance)}.';
}

DateTime? _day(String v) {
  final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(v);
  if (m == null) return null;
  final day = DateTime.utc(int.parse(m[1]!), int.parse(m[2]!), int.parse(m[3]!));
  return day.month == int.parse(m[2]!) ? day : null;
}
