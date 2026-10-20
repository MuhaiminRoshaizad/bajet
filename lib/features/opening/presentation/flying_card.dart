import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../accounts/domain/account_models.dart';
import '../../accounts/presentation/card_face.dart';
import '../../today/presentation/today_total_card.dart';
import '../domain/opening_timeline.dart';
import 'titanium_card.dart';

/// One of the three cards in flight, at [pose]: titanium at [titanium]'s
/// opacity, with its real [face] over it at [shown]'s. It is laid out
/// [base] wide, Today's width, and scaled, so the real face is the card
/// Today shows. Sits in a [Stack].
class FlyingCard extends StatelessWidget {
  const FlyingCard({super.key, required this.pose, required this.base, required this.depth, required this.titanium, this.face, this.shown = 0});

  final CardPose pose;
  final double base;

  /// 0 the back card, 2 the front.
  final int depth;
  final double titanium;
  final Widget? face;
  final double shown;

  @override
  Widget build(BuildContext context) {
    final h = base / cardAspectRatio;
    final face = this.face;
    return Positioned(
      left: pose.centre.dx - base / 2,
      top: pose.centre.dy - h / 2,
      width: base,
      height: h,
      child: Opacity(
        opacity: pose.opacity.clamp(0, 1),
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.rotationZ(pose.turn * math.pi / 180)..scaleByDouble(pose.width / base, pose.width / base, 1, 1),
          child: Stack(children: [
            if (titanium > 0) Opacity(opacity: titanium.clamp(0, 1), child: TitaniumCard(depth: depth, width: base)),
            if (face != null && shown > 0) Opacity(opacity: shown.clamp(0, 1), child: face),
          ]),
        ),
      ),
    );
  }
}

/// The real face of flying card [depth] once it lands in Today's stack:
/// the total in front, the accounts peeking behind it.
Widget stackFace(int depth, List<Account> accounts) =>
    depth == 2 ? const TodayTotalCard() : AccountCard(account: accounts[math.min(1 - depth, accounts.length - 1)]);
