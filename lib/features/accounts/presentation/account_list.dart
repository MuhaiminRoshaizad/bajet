import 'package:flutter/material.dart';

import '../domain/account_models.dart';
import 'card_face.dart';
import 'hold_swell.dart';

/// Where each card sits on Your accounts. At rest the cards overlap like a
/// wallet, each showing a strip with its name and balance. Scrolling opens
/// them downward: the list is held still while the first [open] pixels of
/// scroll go into spreading the cards below the top one apart, until each
/// card is whole with a [gap] beneath it. Past that the page scrolls as a
/// plain list.
class AccountListLayout {
  const AccountListLayout({required this.accounts, required this.width});

  final List<Account> accounts;
  final double width;

  static const strip = 74.0;
  static const gap = 14.0;

  /// How far a scroll opens the cards fully.
  static const open = 220.0;

  /// Room a cash wallet's bills need above it, so they never cover the
  /// balance of the card before.
  static const billRoom = 26.0;

  double get cardHeight => width / cardAspectRatio;

  double _bills(int i) => i < accounts.length && accounts[i].kind == AccountKind.cash ? billRoom : 0;

  /// From card [i]'s top to the next card's, closed and fully open.
  double _closed(int i) => strip + _bills(i + 1);
  double _opened(int i) => cardHeight + gap + _bills(i + 1);

  /// How open the cards are at a scroll [offset], 0 to 1.
  static double openness(double offset) => (offset / open).clamp(0.0, 1.0);

  /// Card [i]'s top within the list, at scroll [offset], with [arrived] how
  /// far the arrival has run, 0 to 1: from all on top of each other to their
  /// strips.
  double top(int i, double offset, {double arrived = 1}) {
    final p = openness(offset);
    var y = offset.clamp(0.0, open) + _bills(0);
    for (var j = 0; j < i; j++) {
      y += _arrival(j, arrived) * (_closed(j) + (_opened(j) - _closed(j)) * p);
    }
    return y;
  }

  /// Each card's own stretch of the arrival, a little after the one above,
  /// sprung so it overshoots and settles; exactly 1 once the arrival ends.
  double _arrival(int j, double arrived) {
    if (arrived >= 1) return 1;
    final step = accounts.length < 2 ? 0.0 : 0.3 / (accounts.length - 1);
    final local = ((arrived - step * j) / (1 - step * (accounts.length - 1))).clamp(0.0, 1.0);
    return Curves.easeOutBack.transform(local);
  }

  /// The list's full height: the open cards, plus the scroll that opens them.
  double get height {
    if (accounts.isEmpty) return 0;
    var y = open + _bills(0);
    for (var j = 0; j < accounts.length - 1; j++) {
      y += _opened(j);
    }
    return y + cardHeight;
  }
}

/// The cards laid out by [AccountListLayout] for the current scroll.
class AccountList extends StatelessWidget {
  const AccountList({super.key, required this.accounts, required this.offset, this.arrived = 1, this.onTap, this.hidden = const {}});

  final List<Account> accounts;
  final double offset;
  final double arrived;
  final ValueChanged<Account>? onTap;

  /// Accounts whose cards are in flight elsewhere, so they hold their place
  /// unseen and never show twice.
  final Set<int> hidden;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final layout = AccountListLayout(accounts: accounts, width: box.maxWidth);
        return SizedBox(
          height: layout.height,
          child: Stack(clipBehavior: Clip.none, children: [
            // Later cards overlap the bottom of the one above.
            for (final (i, a) in accounts.indexed)
              Positioned(
                key: ValueKey('account-card-${a.id}'),
                top: layout.top(i, offset, arrived: arrived),
                left: 0,
                width: box.maxWidth,
                child: Opacity(
                  opacity: hidden.contains(a.id) ? 0 : 1,
                  child: HoldSwell(onTap: onTap == null ? null : () => onTap!(a), child: AccountCard(account: a)),
                ),
              ),
          ]),
        );
      });
}
