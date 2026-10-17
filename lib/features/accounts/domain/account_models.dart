/// Accounts vocabulary: the places money is kept, how each one's card looks,
/// and money moved between them. Amounts are integer sen.
library;

enum AccountKind { cash, bank, ewallet }

/// What an upgraded install's balance, or an older backup's, is filed under
/// until the user says where it really is: a neutral slate card.
const firstAccountName = 'Main account';
const firstAccountColor = 0xFF4A5866;

/// How a card is drawn. Leather and suede are the cash wallet's.
enum CardFinish { matte, gloss, mirror, pearl, frosted, guilloche, leather, suede }

/// A card's colours as ARGB. [ink] is the text colour when the user picked
/// one, such as gold on black; otherwise the text follows the card's
/// lightness.
class CardLook {
  const CardLook({required this.color, this.ink, this.finish = CardFinish.matte});

  final int color;
  final int? ink;
  final CardFinish finish;

  CardLook copyWith({int? color, int? Function()? ink, CardFinish? finish}) =>
      CardLook(color: color ?? this.color, ink: ink == null ? this.ink : ink(), finish: finish ?? this.finish);

  @override
  bool operator ==(Object other) => other is CardLook && other.color == color && other.ink == ink && other.finish == finish;

  @override
  int get hashCode => Object.hash(color, ink, finish);
}

class Account {
  const Account({
    required this.id,
    required this.kind,
    required this.name,
    required this.openingBalance,
    required this.balance,
    required this.look,
    this.nickname,
  });

  final int id;
  final AccountKind kind;

  /// The provider as plain text, such as a bank's name; "Cash" for cash.
  final String name;
  final String? nickname;

  /// What it held on the opening date.
  final int openingBalance;

  /// What it holds now: the opening balance, its entries and its transfers.
  final int balance;
  final CardLook look;

  /// What the user calls it: the nickname if it has one.
  String get called => nickname ?? name;

  Account copyWith({String? name, String? Function()? nickname, CardLook? look}) => Account(
        id: id,
        kind: kind,
        name: name ?? this.name,
        nickname: nickname == null ? this.nickname : nickname(),
        openingBalance: openingBalance,
        balance: balance,
        look: look ?? this.look,
      );
}

/// An account not yet saved, as first run or "Add an account" builds it.
class AccountDraft {
  const AccountDraft({required this.kind, required this.name, required this.look, this.nickname, this.balance = 0});

  final AccountKind kind;
  final String name;
  final String? nickname;

  /// What is in it now.
  final int balance;
  final CardLook look;
}

/// The total card has no account behind it; with no colour it follows the
/// app's own light or dark surface.
class TotalCardLook {
  const TotalCardLook({this.color, this.finish = CardFinish.matte});

  final int? color;
  final CardFinish finish;

  @override
  bool operator ==(Object other) => other is TotalCardLook && other.color == color && other.finish == finish;

  @override
  int get hashCode => Object.hash(color, finish);
}

/// Money moved from one account to another: neither spending nor income.
class Transfer {
  const Transfer({required this.id, required this.day, required this.fromId, required this.toId, required this.amount, this.note});

  final int id;
  final DateTime day;
  final int fromId;
  final int toId;
  final int amount;
  final String? note;

  bool touches(int accountId) => fromId == accountId || toId == accountId;
}

/// What still points at an account, which deleting it has to deal with.
class AccountUse {
  const AccountUse({required this.entries, required this.transfers, required this.bills});

  final int entries;
  final int transfers;

  /// The names of the bills and pay paid from or into it.
  final List<String> bills;

  bool get isEmpty => entries == 0 && transfers == 0 && bills.isEmpty;
}

/// What [AccountRepository.deleteAccount] took away, kept so Undo can put it
/// back. Only the repository that made it can restore it.
class AccountRemoval {
  const AccountRemoval(this.account, {this.movedTo});

  final Account account;

  /// The account its history joined, or null when that was deleted too.
  final int? movedTo;
}
