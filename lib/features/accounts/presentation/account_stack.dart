import 'package:flutter/material.dart';

import '../domain/account_models.dart';
import 'card_face.dart';

/// Today's total card with the accounts stacked behind it, at most two edges
/// peeking out above, so the stack is the same height however many accounts
/// there are.
class AccountStack extends StatelessWidget {
  const AccountStack({super.key, required this.accounts, required this.total});

  final List<Account> accounts;
  final Widget total;

  /// How much of each card behind the total shows, and how many may show.
  static const peek = 9.0;
  static const peeks = 2;

  /// Kept clear above the stack for a cash wallet's bills, so they never
  /// reach into whatever sits above it.
  static const billRoom = 24.0;

  /// The height the stack takes, for a card of [width].
  static double height(double width, int accounts) => billRoom + accounts.clamp(0, peeks) * peek + width / cardAspectRatio;

  /// How small a card behind the total is drawn, [depth] 1 the nearest.
  static double scaleAt(int depth) => 1 - depth * 0.035;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final w = box.maxWidth;
        final shown = accounts.length.clamp(0, peeks);
        return SizedBox(
          height: height(w, accounts.length),
          child: Stack(clipBehavior: Clip.none, children: [
            // The deeper a card, the higher its edge and the narrower it is;
            // the others wait out of sight behind the total.
            for (var i = shown - 1; i >= 0; i--)
              Positioned(
                key: ValueKey('account-card-${accounts[i].id}'),
                top: billRoom + (shown - 1 - i) * peek,
                left: 0,
                width: w,
                child: Transform.scale(scale: scaleAt(i + 1), alignment: Alignment.topCenter, child: AccountCard(account: accounts[i])),
              ),
            Positioned(key: const ValueKey('total-card'), top: billRoom + shown * peek, left: 0, width: w, child: total),
          ]),
        );
      });
}

/// Where Today's stack was on screen when it was tapped, so Your accounts can
/// slide each card out of exactly that place and back into it.
class StackPlaces {
  const StackPlaces(this.stack, this.count);

  /// The stack's own rect, in global coordinates.
  final Rect stack;
  final int count;

  double get _height => stack.width / cardAspectRatio;
  int get _shown => count.clamp(0, AccountStack.peeks);

  Rect get total => Rect.fromLTWH(stack.left, stack.top + AccountStack.billRoom + _shown * AccountStack.peek, stack.width, _height);

  /// Account [i]'s card; those that do not peek out wait behind the deepest
  /// one that does.
  Rect card(int i) {
    final depth = (i + 1).clamp(1, _shown == 0 ? 1 : _shown);
    final k = AccountStack.scaleAt(depth);
    final top = stack.top + AccountStack.billRoom + (_shown - depth) * AccountStack.peek;
    return Rect.fromLTWH(stack.left + stack.width * (1 - k) / 2, top, stack.width * k, _height * k);
  }
}
