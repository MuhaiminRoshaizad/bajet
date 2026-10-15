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
                child: Transform.scale(scale: 1 - (i + 1) * 0.035, alignment: Alignment.topCenter, child: AccountCard(account: accounts[i])),
              ),
            Positioned(key: const ValueKey('total-card'), top: billRoom + shown * peek, left: 0, width: w, child: total),
          ]),
        );
      });
}
