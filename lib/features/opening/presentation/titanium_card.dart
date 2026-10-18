import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../accounts/presentation/card_face.dart' show cardAspectRatio;
import '../domain/opening_timeline.dart';

/// The launcher icon's three metals, back to front.
const titaniumShades = [Color(0xFF5F656D), Color(0xFF9AA0A8), Color(0xFFD8DBDF)];

/// The graphite the opening plays on, the same as the launch screen's.
const graphite = Color(0xFF121418);

/// The wordmark's letters, each drawn on its own, as the splash animation
/// draws them too.
const wordmarkStyle = TextStyle(fontFamily: 'Figtree', fontSize: 34 * OpeningPlan.zoom, height: 1, fontWeight: FontWeight.w800, letterSpacing: .68 * OpeningPlan.zoom, color: Color(0xFFE3E9EE));

/// One of the icon's titanium cards at [width], flat like the splash
/// animation's, so the hand-over from Android shows no seam. The front card
/// carries the chip.
class TitaniumCard extends StatelessWidget {
  const TitaniumCard({super.key, required this.depth, required this.width});

  /// 0 the back card, 2 the front.
  final int depth;
  final double width;

  /// The splash animation draws the same card from these, at
  /// [OpeningPlan.cardWidth].
  static double radiusAt(double width) => 16 * width / 330;
  static Rect chipAt(double width) => Rect.fromLTWH(12.5 * width / 100, 22 * width / 100, 19 * width / 100, 15 * width / 100);

  @override
  Widget build(BuildContext context) {
    final chip = chipAt(width);
    return SizedBox(
      width: width,
      height: width / cardAspectRatio,
      child: DecoratedBox(
        decoration: BoxDecoration(color: titaniumShades[depth], borderRadius: BorderRadius.circular(radiusAt(width))),
        child: depth < 2
            ? null
            : Stack(children: [
                Positioned.fromRect(
                  rect: chip,
                  child: DecoratedBox(decoration: BoxDecoration(color: graphite.withValues(alpha: .32), borderRadius: BorderRadius.circular(4 * width / 330))),
                ),
              ]),
      ),
    );
  }
}

/// The three cards fanned as in the icon, small, where the lock screen
/// would show a padlock. The opening's cards land exactly on it.
class FanMark extends StatelessWidget {
  const FanMark({super.key, this.scale = .55});

  final double scale;

  static Size sizeFor(double scale) => Size(72 * OpeningPlan.k * scale, 46 * OpeningPlan.k * scale);

  @override
  Widget build(BuildContext context) {
    final size = sizeFor(scale), centre = size.center(Offset.zero);
    final w = OpeningPlan.cardWidth * scale, h = w / cardAspectRatio;
    return SizedBox.fromSize(
      size: size,
      child: Stack(clipBehavior: Clip.none, children: [
        for (final (i, a) in OpeningPlan.angles.indexed)
          Positioned(
            left: centre.dx + OpeningPlan.fanOffset(a).dx * scale - w / 2,
            top: centre.dy + OpeningPlan.fanOffset(a).dy * scale - h / 2,
            child: Transform.rotate(angle: a * math.pi / 180, child: TitaniumCard(depth: i, width: w)),
          ),
      ]),
    );
  }
}

/// The app icon: the titanium fan on its graphite tile, [size] across.
class AppIconTile extends StatelessWidget {
  const AppIconTile({super.key, this.size = 56});

  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size * 16 / 56),
          gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF1F232A), graphite]),
        ),
        alignment: Alignment.center,
        child: FanMark(scale: .36 * size / 56),
      );
}
