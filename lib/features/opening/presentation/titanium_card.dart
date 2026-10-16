import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../accounts/presentation/card_face.dart' show cardAspectRatio;
import '../domain/opening_timeline.dart';

/// The launcher icon's three metals, back to front.
const titaniumShades = [Color(0xFF5F656D), Color(0xFF9AA0A8), Color(0xFFD8DBDF)];

/// The graphite the opening plays on, the same as the launch screen's.
const graphite = Color(0xFF121418);

/// One of the icon's titanium cards at [width]. The front card carries the
/// chip and, while [sheen] runs from -1.3 to 1.3, a band of light crossing it.
class TitaniumCard extends StatelessWidget {
  const TitaniumCard({super.key, required this.depth, required this.width, this.sheen});

  /// 0 the back card, 2 the front.
  final int depth;
  final double width;
  final double? sheen;

  @override
  Widget build(BuildContext context) {
    final h = width / cardAspectRatio, s = width / 100;
    final radius = BorderRadius.circular(16 * width / 330);
    return SizedBox(
      width: width,
      height: h,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: titaniumShades[depth],
          borderRadius: radius,
          boxShadow: const [BoxShadow(color: Color(0xB3000000), offset: Offset(0, 10), blurRadius: 22, spreadRadius: -12)],
        ),
        child: depth < 2
            ? null
            : ClipRRect(
                borderRadius: radius,
                child: Stack(children: [
                  Positioned(
                    left: 12.5 * s,
                    top: 22 * s,
                    width: 19 * s,
                    height: 15 * s,
                    child: DecoratedBox(decoration: BoxDecoration(color: graphite.withValues(alpha: .32), borderRadius: BorderRadius.circular(4 * width / 330))),
                  ),
                  if (sheen case final f? when f > -1.3 && f < 1.3)
                    Positioned(
                      left: -0.1 * width + f * 1.2 * width,
                      top: -0.3 * h,
                      width: 1.2 * width,
                      height: 1.6 * h,
                      child: const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            // The mock-up's 105° band.
                            begin: Alignment(-0.966, -0.259),
                            end: Alignment(0.966, 0.259),
                            colors: [Color(0x00FFFFFF), Color(0x99FFFFFF), Color(0x00FFFFFF)],
                            stops: [.38, .5, .62],
                          ),
                        ),
                      ),
                    ),
                ]),
              ),
      ),
    );
  }
}

/// The three cards fanned as in the icon, small, where the lock screen
/// would show a padlock. The opening's cards land exactly on it.
class FanMark extends StatelessWidget {
  const FanMark({super.key, this.scale = .45});

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
