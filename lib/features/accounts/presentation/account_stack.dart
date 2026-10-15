import 'package:flutter/material.dart';

import '../domain/account_models.dart';
import 'card_face.dart';

/// The total card with the accounts behind it. At [spread] 0 they are
/// stacked, at most two edges peeking out above the total, so the stack is
/// the same height however many accounts there are. At 1 they are fanned
/// out below it, each showing its top strip like cards in a wallet.
class AccountStack extends StatelessWidget {
  const AccountStack({
    super.key,
    required this.accounts,
    required this.total,
    required this.spread,
    this.onAccountTap,
    this.onTotalTap,
  });

  final List<Account> accounts;
  final Widget total;

  /// 0 stacked, 1 fanned out; values past 1 overshoot, for the bounce.
  final double spread;
  final ValueChanged<Account>? onAccountTap;
  final VoidCallback? onTotalTap;

  /// How much of each card behind the total shows, and how many may show.
  static const peek = 9.0;
  static const peeks = 2;

  /// Fanned out: room for the total's balance and plan, then each account's
  /// name and balance. The first strip also leaves room for a cash wallet's
  /// bills.
  static const totalStrip = 146.0;
  static const strip = 74.0;

  /// Kept clear above the stack for a cash wallet's bills, so they never
  /// reach into whatever sits above it.
  static const billRoom = 24.0;

  /// The height the stack takes when stacked, for a card of [width].
  static double stackedHeight(double width, int accounts) => billRoom + (accounts.clamp(0, peeks)) * peek + width / cardAspectRatio;

  static double spreadHeight(double width, int accounts) =>
      billRoom + (accounts == 0 ? width / cardAspectRatio : totalStrip + (accounts - 1) * strip + width / cardAspectRatio);

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final w = box.maxWidth;
        final n = accounts.length;
        final shown = n.clamp(0, peeks);
        final t = spread;
        double between(double a, double b, double k) => a + (b - a) * k;

        // Each card follows a little after the one above it.
        double cardT(int i) => ((t * (1 + 0.06 * n)) - 0.06 * i).clamp(-0.2, 1.2);

        final placed = <Widget>[];
        for (var i = 0; i < n; i++) {
          final k = cardT(i);
          final depth = i < shown ? i + 1 : shown;
          final stackedTop = (shown - depth) * peek;
          final top = billRoom + between(stackedTop, totalStrip + i * strip, k);
          final scale = between(1 - depth * 0.035, 1, k.clamp(0, 1));
          final opacity = i < shown ? 1.0 : k.clamp(0.0, 1.0);
          final account = accounts[i];
          placed.add(Positioned(
            key: ValueKey('account-card-${account.id}'),
            top: top,
            left: 0,
            width: w,
            child: Opacity(
              opacity: opacity,
              child: Transform.scale(
                scale: scale,
                alignment: Alignment.topCenter,
                child: GestureDetector(
                  onTap: onAccountTap == null ? null : () => onAccountTap!(account),
                  child: AccountCard(account: account),
                ),
              ),
            ),
          ));
        }
        final totalCard = Positioned(
          key: const ValueKey('total-card'),
          top: billRoom + between(shown * peek, 0, t.clamp(0, 1)),
          left: 0,
          width: w,
          child: GestureDetector(onTap: onTotalTap, child: total),
        );
        // Stacked, the total is in front; fanned out, each account overlaps
        // the bottom of the card above it.
        final fanned = t > 0.5;
        return SizedBox(
          height: between(stackedHeight(w, n), spreadHeight(w, n), t.clamp(0, 1)),
          child: Stack(
            clipBehavior: Clip.none,
            children: fanned ? [totalCard, ...placed] : [...placed.reversed, totalCard],
          ),
        );
      });
}
