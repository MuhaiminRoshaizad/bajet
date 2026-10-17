import 'dart:math' as math;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import '../../../core/money/money.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_spacing.dart';
import '../../ledger/domain/ledger_models.dart';

/// Slices take these in order of size, so neighbours never share a colour
/// the way two categories with the same tint would.
const _sliceTints = [Tint.apricot, Tint.sky, Tint.sage, Tint.teal, Tint.rose, Tint.olive];

/// Past six slices a ring stops being readable, so the rest share one,
/// named so it cannot be mistaken for the Other category.
const _maxSlices = 6;

/// Money out as a ring, one slice per category, with the total in the middle
/// and a key underneath giving each one's amount and share. It sweeps in and
/// settles with a small bounce whenever its figures change.
class CategoryRing extends StatefulWidget {
  const CategoryRing({super.key, required this.byCategory, required this.categories});

  /// Amount per category key, largest first.
  final List<(String, int)> byCategory;
  final Map<String, Category> categories;

  @override
  State<CategoryRing> createState() => _CategoryRingState();
}

class _CategoryRingState extends State<CategoryRing> with SingleTickerProviderStateMixin {
  late final _sweep = AnimationController.unbounded(vsync: this);
  var _played = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_played) return;
    _played = true;
    _play();
  }

  @override
  void didUpdateWidget(CategoryRing old) {
    super.didUpdateWidget(old);
    if (!listEquals(old.byCategory, widget.byCategory)) _play();
  }

  void _play() {
    if (MediaQuery.disableAnimationsOf(context)) {
      _sweep.value = 1;
    } else {
      _sweep.animateWith(SpringSimulation(AppMotion.spring, 0, 1, 0));
    }
  }

  @override
  void dispose() {
    _sweep.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final all = widget.byCategory;
    final shown = all.length <= _maxSlices ? all : all.take(_maxSlices - 1).toList();
    final other = all.skip(shown.length).fold(0, (s, e) => s + e.$2);
    final total = all.fold(0, (s, e) => s + e.$2);
    final slices = [
      for (final (n, (key, amount)) in shown.indexed)
        (widget.categories[key]?.label ?? key, amount, c.tintInk(_sliceTints[n]), widget.categories[key]?.isFixed ?? false),
      if (other > 0) ('Everything else', other, c.tintInk(Tint.neutral), false),
    ];
    String share(int amount) => '${(amount / math.max(1, total) * 100).round()}%';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Semantics(
            label: 'Money out ${Money.format(total)}',
            excludeSemantics: true,
            child: SizedBox.square(
              dimension: 176,
              child: AnimatedBuilder(
                animation: _sweep,
                builder: (context, child) => Transform.scale(
                  // The sweep stops at a full circle; the overshoot shows as
                  // the ring swelling a touch past its size and settling.
                  scale: 0.9 + 0.1 * _sweep.value,
                  child: CustomPaint(
                    painter: _RingPainter(
                      slices: [for (final s in slices) (s.$2 / math.max(1, total), s.$3)],
                      sweep: _sweep.value.clamp(0, 1).toDouble(),
                      track: c.well,
                    ),
                    child: child,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Money out', style: TextStyle(color: c.muted, fontSize: 12)),
                      Text(Money.format(total), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, fontFeatures: [FontFeature.tabularFigures()])),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.l),
        for (final (label, amount, colour, fixed) in slices)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.s),
            child: Semantics(
              label: '$label ${Money.format(amount)}',
              value: '${fixed ? 'fixed, ' : ''}${share(amount)}',
              excludeSemantics: true,
              child: Row(
                children: [
                  Container(width: 12, height: 12, decoration: BoxDecoration(color: colour, borderRadius: BorderRadius.circular(4))),
                  const SizedBox(width: AppSpacing.m),
                  Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
                  if (fixed) ...[
                    const SizedBox(width: AppSpacing.s),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s - 2),
                      decoration: BoxDecoration(border: Border.all(color: c.line), borderRadius: BorderRadius.circular(AppRadii.pill)),
                      child: Text('Fixed', style: TextStyle(color: c.muted, fontSize: 11, fontWeight: FontWeight.w700)),
                    ),
                  ],
                  const Spacer(),
                  Text(Money.format(amount), style: const TextStyle(fontWeight: FontWeight.w700, fontFeatures: [FontFeature.tabularFigures()])),
                  SizedBox(
                    width: 44,
                    child: Text(share(amount), textAlign: TextAlign.end, style: TextStyle(color: c.muted, fontSize: 13, fontFeatures: const [FontFeature.tabularFigures()])),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Slices clockwise from the top, a hair apart, over a sunken track; only the
/// first [sweep] of the circle is drawn yet.
class _RingPainter extends CustomPainter {
  _RingPainter({required this.slices, required this.sweep, required this.track});

  final List<(double, Color)> slices;
  final double sweep;
  final Color track;

  static const _stroke = 22.0;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(_stroke / 2);
    Paint stroke(Color colour) => Paint()
      ..color = colour
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke;
    canvas.drawArc(rect, 0, math.pi * 2, false, stroke(track));
    final gap = slices.length > 1 ? 0.035 : 0.0;
    var start = -math.pi / 2;
    final end = start + math.pi * 2 * sweep;
    for (final (fraction, colour) in slices) {
      final full = math.pi * 2 * fraction;
      final length = math.min(full - gap, end - start);
      if (length > 0) canvas.drawArc(rect, start, length, false, stroke(colour));
      start += full;
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.sweep != sweep || !listEquals(old.slices, slices) || old.track != track;
}
