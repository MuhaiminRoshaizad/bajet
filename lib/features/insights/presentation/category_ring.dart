import 'dart:math' as math;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import '../../../core/money/money.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_spacing.dart';
import '../../ledger/domain/ledger_models.dart';
import '../../ledger/presentation/entry_drawer.dart';

/// Slices take these in order of size, so neighbours never share a colour
/// the way two categories with the same tint would.
const _sliceTints = [Tint.apricot, Tint.sky, Tint.sage, Tint.teal, Tint.rose, Tint.olive];

/// Past six slices a ring stops being readable, so the rest share one,
/// named so it cannot be mistaken for the Other category.
const _maxSlices = 6;

/// Money out as a ring, one slice per category, with the total in the middle
/// and a key underneath giving each one's amount and share. It sweeps in and
/// settles with a small bounce whenever its figures change. Tapping a slice,
/// or its row in the key, opens that category: the slice springs out, the
/// rest fade back, the middle names it, and its entries open under its row.
class CategoryRing extends StatefulWidget {
  const CategoryRing({
    super.key,
    required this.byCategory,
    required this.categories,
    required this.entries,
    required this.today,
    required this.onOpenEntry,
  });

  /// Amount per category key, largest first.
  final List<(String, int)> byCategory;
  final Map<String, Category> categories;

  /// The entries behind [byCategory], newest first.
  final List<Entry> entries;
  final DateTime today;
  final ValueChanged<Entry> onOpenEntry;

  @override
  State<CategoryRing> createState() => _CategoryRingState();
}

class _CategoryRingState extends State<CategoryRing> with TickerProviderStateMixin {
  late final _sweep = AnimationController.unbounded(vsync: this);

  /// How far the open slice has sprung out, and the one just closed has yet
  /// to settle back.
  late final _pop = AnimationController.unbounded(vsync: this);
  late final _drop = AnimationController.unbounded(vsync: this);

  /// How far the other slices and rows have faded back.
  late final _focus = AnimationController(vsync: this, duration: AppMotion.fast);
  int? _open, _dropped;
  var _played = false;

  bool get _still => MediaQuery.disableAnimationsOf(context);

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
    if (listEquals(old.byCategory, widget.byCategory)) return;
    // Another period: whatever was open belongs to the last one.
    _open = _dropped = null;
    _pop.value = _drop.value = _focus.value = 0;
    _play();
  }

  void _play() {
    if (_still) {
      _sweep.value = 1;
    } else {
      _sweep.animateWith(SpringSimulation(AppMotion.spring, 0, 1, 0, snapToEnd: true));
    }
  }

  void _spring(AnimationController a, double to) {
    if (_still) {
      a.value = to;
    } else {
      a.animateWith(SpringSimulation(AppMotion.spring, a.value, to, 0, snapToEnd: true));
    }
  }

  /// Opens slice [i], or closes it when it is the one open; null closes.
  void _choose(int? i) {
    final next = i == _open ? null : i;
    setState(() {
      if (_open != null) {
        _dropped = _open;
        _drop.value = _pop.value;
        _spring(_drop, 0);
      }
      _open = next;
      if (next != null) {
        _pop.value = 0;
        _spring(_pop, 1);
      }
    });
    if (next == null) {
      _focus.reverse();
    } else {
      _focus.forward();
    }
  }

  /// The slice under [at] in the ring's square, or null for its middle.
  int? _sliceAt(Offset at, List<double> fractions) {
    const half = _ring / 2;
    final d = at - const Offset(half, half);
    if (d.distance < half - _RingPainter._stroke - 4) return null;
    var turn = math.atan2(d.dx, -d.dy) / (math.pi * 2);
    if (turn < 0) turn += 1;
    var from = 0.0;
    for (final (i, f) in fractions.indexed) {
      from += f;
      if (turn <= from) return i;
    }
    return fractions.length - 1;
  }

  @override
  void dispose() {
    _sweep.dispose();
    _pop.dispose();
    _drop.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final all = widget.byCategory;
    final shown = all.length <= _maxSlices ? all : all.take(_maxSlices - 1).toList();
    final rest = {for (final (key, _) in all.skip(shown.length)) key};
    final other = all.skip(shown.length).fold(0, (s, e) => s + e.$2);
    final total = all.fold(0, (s, e) => s + e.$2);
    final slices = [
      for (final (n, (key, amount)) in shown.indexed)
        (widget.categories[key]?.label ?? key, amount, c.tintInk(_sliceTints[n]), widget.categories[key]?.isFixed ?? false, {key}),
      if (other > 0) ('Everything else', other, c.tintInk(Tint.neutral), false, rest),
    ];
    final fractions = [for (final s in slices) s.$2 / math.max(1, total)];
    String share(int amount) => '${(amount / math.max(1, total) * 100).round()}%';
    List<Entry> entriesOf(Set<String> keys) => widget.entries.where((e) => keys.contains(e.categoryKey)).toList();
    final open = _open;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Semantics(
            label: open == null ? 'Money out ${Money.format(total)}' : '${slices[open].$1} ${Money.format(slices[open].$2)}',
            excludeSemantics: true,
            child: GestureDetector(
              onTapUp: (d) {
                final i = _sliceAt(d.localPosition, fractions);
                if (i != null || open != null) _choose(i ?? open);
              },
              child: SizedBox.square(
                dimension: _ring,
                child: AnimatedBuilder(
                  animation: Listenable.merge([_sweep, _pop, _drop, _focus]),
                  builder: (context, child) => Transform.scale(
                    // The sweep stops at a full circle; the overshoot shows as
                    // the ring swelling a touch past its size and settling.
                    scale: 0.9 + 0.1 * _sweep.value,
                    child: CustomPaint(
                      painter: _RingPainter(
                        slices: [
                          for (final (i, s) in slices.indexed)
                            (
                              fractions[i],
                              // Only the open slice stays lit; the one just closed
                              // dims with the rest as it drops back.
                              s.$3.withValues(alpha: i == _open ? 1 : 1 - 0.65 * _focus.value),
                              i == _open ? _pop.value : (i == _dropped ? _drop.value : 0.0),
                            ),
                        ],
                        sweep: _sweep.value.clamp(0, 1).toDouble(),
                        track: c.well,
                      ),
                      child: child,
                    ),
                  ),
                  // Money never overshoots: the middle changes over, no bounce.
                  // It stays inside the hole, smaller under large text rather
                  // than running onto the ring.
                  child: Center(
                    child: SizedBox(
                      width: _hole,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: AnimatedSwitcher(
                          duration: _still ? Duration.zero : AppMotion.fast,
                          child: Column(
                            key: ValueKey(open),
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(open == null ? 'Money out' : slices[open].$1, style: TextStyle(color: c.muted, fontSize: 12)),
                              Text(
                                Money.format(open == null ? total : slices[open].$2),
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, fontFeatures: [FontFeature.tabularFigures()]),
                              ),
                              if (open != null)
                                Text(
                                  () {
                                    final n = entriesOf(slices[open].$5).length;
                                    return '${share(slices[open].$2)} · $n ${n == 1 ? 'entry' : 'entries'}';
                                  }(),
                                  style: TextStyle(color: c.muted, fontSize: 12, fontFeatures: const [FontFeature.tabularFigures()]),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.l),
        for (final (i, (label, amount, colour, fixed, keys)) in slices.indexed) ...[
          AnimatedOpacity(
            opacity: open == null || open == i ? 1 : 0.45,
            duration: _still ? Duration.zero : AppMotion.fast,
            child: Semantics(
              label: '$label ${Money.format(amount)}',
              value: '${fixed ? 'fixed, ' : ''}${share(amount)}',
              button: true,
              expanded: open == i,
              excludeSemantics: true,
              child: InkWell(
                key: ValueKey('ring-row-$label'),
                onTap: () => _choose(i),
                borderRadius: BorderRadius.circular(AppRadii.control),
                child: AnimatedContainer(
                  duration: _still ? Duration.zero : AppMotion.fast,
                  constraints: const BoxConstraints(minHeight: 44),
                  decoration: BoxDecoration(color: open == i ? c.well : null, borderRadius: BorderRadius.circular(AppRadii.control)),
                  child: Row(
                    children: [
                      Container(width: 12, height: 12, decoration: BoxDecoration(color: colour, borderRadius: BorderRadius.circular(4))),
                      const SizedBox(width: AppSpacing.m),
                      // The name takes all the room left, so every amount ends on
                      // the card's right edge whatever the name's length.
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
                            if (fixed) ...[
                              const SizedBox(width: AppSpacing.s),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s - 2),
                                decoration: BoxDecoration(border: Border.all(color: c.line), borderRadius: BorderRadius.circular(AppRadii.pill)),
                                child: Text('Fixed', style: TextStyle(color: c.muted, fontSize: 11, fontWeight: FontWeight.w700)),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Text(Money.format(amount), style: const TextStyle(fontWeight: FontWeight.w700, fontFeatures: [FontFeature.tabularFigures()])),
                      // As wide as "100%" at this size of text, so shares never
                      // wrap and every row's column lines up.
                      SizedBox(
                        width: 44 * math.max(1.0, MediaQuery.textScalerOf(context).scale(13) / 13),
                        child: Text(share(amount), maxLines: 1, softWrap: false, textAlign: TextAlign.end, style: TextStyle(color: c.muted, fontSize: 13, fontFeatures: const [FontFeature.tabularFigures()])),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      AnimatedRotation(
                        turns: open == i ? 0.5 : 0,
                        duration: _still ? Duration.zero : AppMotion.enter,
                        curve: Curves.easeOutBack,
                        child: Icon(Icons.expand_more_rounded, size: 20, color: c.muted),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Its entries open under it like a drawer, passing their height a
          // little before settling.
          AnimatedSize(
            duration: _still ? Duration.zero : AppMotion.enter,
            curve: Curves.easeOutBack,
            alignment: Alignment.topCenter,
            child: open == i
                ? EntryDrawer(
                    key: ValueKey(('ring-entries', i)),
                    entries: entriesOf(keys),
                    categories: widget.categories,
                    today: widget.today,
                    onOpen: widget.onOpenEntry,
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ],
    );
  }
}

const _ring = 176.0;

/// The room inside the ring for its middle: the hole, less a margin for the
/// open slice, which thickens.
const _hole = _ring - 2 * 22.0 - 24;

/// Slices clockwise from the top, a hair apart, over a sunken track; only the
/// first [sweep] of the circle is drawn yet. A slice popped out by its third
/// value sits further out and thicker.
class _RingPainter extends CustomPainter {
  _RingPainter({required this.slices, required this.sweep, required this.track});

  final List<(double, Color, double)> slices;
  final double sweep;
  final Color track;

  static const _stroke = 22.0;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(_stroke / 2);
    Paint stroke(Color colour, double width) => Paint()
      ..color = colour
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;
    canvas.drawArc(rect, 0, math.pi * 2, false, stroke(track, _stroke));
    final gap = slices.length > 1 ? 0.035 : 0.0;
    var start = -math.pi / 2;
    final end = start + math.pi * 2 * sweep;
    for (final (fraction, colour, pop) in slices) {
      final full = math.pi * 2 * fraction;
      final length = math.min(full - gap, end - start);
      if (length > 0) canvas.drawArc(rect.inflate(7 * pop), start, length, false, stroke(colour, _stroke + 5 * pop));
      start += full;
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.sweep != sweep || !listEquals(old.slices, slices) || old.track != track;
}
