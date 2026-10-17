import 'dart:math' as math;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../../core/money/money.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/soft.dart';

/// One day of the week: its flexible spend and what the rhythm planned.
class WeekDay {
  const WeekDay({required this.date, required this.label, required this.spent, required this.planned});

  final DateTime date;
  final String label;
  final int spent;
  final int planned;
}

/// The week against its allowance as a raised dial: the arc fills as the
/// week's flexible money goes, each spending day owns the stretch its plan
/// covers, and a marker shows where the plan says the week should be by
/// tonight. The centre says what is left, and the line under it what that
/// leaves for each spending day still to come.
///
/// When spending is logged the arc springs past the new amount and settles
/// back on it, the stretch just added glows a moment, and the dial dips as if
/// pressed. The figures count to their new value without overshooting.
class WeekDial extends ConsumerStatefulWidget {
  const WeekDial({super.key, required this.days, required this.spent, required this.cap});

  /// Monday to Sunday.
  final List<WeekDay> days;
  final int spent;
  final int cap;

  @override
  ConsumerState<WeekDial> createState() => _WeekDialState();
}

class _WeekDialState extends ConsumerState<WeekDial> with TickerProviderStateMixin {
  late final _arc = AnimationController.unbounded(vsync: this);
  late final _press = AnimationController.unbounded(vsync: this, value: 1);
  late final _glow = AnimationController(vsync: this, duration: const Duration(milliseconds: 500), value: 1);
  var _glowFrom = 0.0, _glowTo = 0.0;
  var _started = false;

  double _fraction(int spent) => widget.cap <= 0 ? (spent > 0 ? 1 : 0) : math.min(1, spent / widget.cap);

  bool get _still => MediaQuery.disableAnimationsOf(context);

  void _springTo(AnimationController c, double from, double to) => c.animateWith(SpringSimulation(AppMotion.spring, from, to, 0, snapToEnd: true));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    // The arc grows from nothing as the card rises into place.
    if (_still) {
      _arc.value = _fraction(widget.spent);
    } else {
      _springTo(_arc, 0, _fraction(widget.spent));
    }
  }

  @override
  void didUpdateWidget(WeekDial old) {
    super.didUpdateWidget(old);
    final to = _fraction(widget.spent);
    if (widget.spent == old.spent && widget.cap == old.cap) return;
    if (_still) {
      _arc.value = to;
      return;
    }
    final from = _arc.value;
    _springTo(_arc, from, to);
    if (widget.spent > old.spent) {
      _glowFrom = math.min(from, to);
      _glowTo = to;
      _glow.forward(from: 0);
      _press.value = 0.97;
      _springTo(_press, 0.97, 1);
    }
  }

  @override
  void dispose() {
    _arc.dispose();
    _press.dispose();
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final today = ref.watch(todayProvider);
    final days = widget.days;
    final left = widget.cap - widget.spent;
    final planBy = days.where((d) => !d.date.isAfter(today)).fold(0, (s, d) => s + d.planned);
    final ahead = widget.spent > planBy;
    final daysLeft = days.where((d) => !d.date.isBefore(today) && d.planned > 0).length;
    final warn = left < 0 || ahead;
    final pace = left < 0
        ? '${Money.format(-left)} over this week'
        : daysLeft == 0
            ? 'No spending days left this week'
            : '${ahead ? 'Ahead of plan for today. ' : ''}${Money.format(left ~/ daysLeft)} a day for the $daysLeft spending ${daysLeft == 1 ? 'day' : 'days'} left';

    // Each spending day's stretch of the dial, in order, as fractions of the
    // allowance; a plan past the allowance is squeezed off the end.
    final stretches = <(double, double, String, bool)>[];
    var at = 0;
    for (final d in days.where((d) => d.planned > 0)) {
      if (widget.cap <= 0) break;
      stretches.add((math.min(1, at / widget.cap), math.min(1, (at + d.planned) / widget.cap), d.label.substring(0, 1), d.date == today));
      at += d.planned;
    }

    return Column(
      children: [
        Semantics(
          label: '${left >= 0 ? '${Money.format(left)} left' : '${Money.format(-left)} over'} of ${Money.format(widget.cap)} this week. '
              'By tonight the plan allows ${Money.format(planBy)}.',
          excludeSemantics: true,
          child: LayoutBuilder(
            builder: (context, box) {
              final size = math.min(220.0, box.maxWidth);
              return ScaleTransition(
                scale: _press,
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: c.background, boxShadow: softShadows(c, AppDepth.card)),
                  child: TweenAnimationBuilder<Color?>(
                    tween: ColorTween(end: warn ? c.bad : c.primary),
                    duration: AppMotion.fast,
                    builder: (context, colour, child) => AnimatedBuilder(
                      animation: Listenable.merge([_arc, _glow]),
                      builder: (context, child) => CustomPaint(
                        painter: _DialPainter(
                          value: _arc.value,
                          colour: colour!,
                          glow: Color.lerp(c.primarySoft, colour, Curves.easeOut.transform(_glow.value))!,
                          glowFrom: _glow.value < 1 ? _glowFrom : 0,
                          glowTo: _glow.value < 1 ? math.min(_glowTo, _arc.value.clamp(0, 1).toDouble()) : 0,
                          stretches: stretches,
                          marker: widget.cap <= 0 ? null : math.min(1, planBy / widget.cap),
                          track: c.well,
                          divider: c.background,
                          ink: c.ink,
                          muted: c.muted,
                          // A painter's text has no theme, so it is handed
                          // the app's own type to match the rest of the card.
                          letters: DefaultTextStyle.of(context).style.copyWith(fontSize: 11),
                        ),
                        child: child,
                      ),
                      child: child,
                    ),
                    child: Center(
                      child: SizedBox.square(
                        dimension: size * 0.54,
                        child: SoftWell(
                          circle: true,
                          padding: const EdgeInsets.all(AppSpacing.m),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _Counting(
                                  value: left.abs(),
                                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: left < 0 ? c.bad : c.ink, fontFeatures: const [FontFeature.tabularFigures()]),
                                ),
                                Text(left < 0 ? 'over this week' : 'left this week', style: TextStyle(color: c.muted, fontSize: 12)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.l),
        Text('Spent ${Money.format(widget.spent)} of ${Money.formatWhole(widget.cap)}', style: TextStyle(color: c.muted)),
        const SizedBox(height: AppSpacing.xs),
        AnimatedDefaultTextStyle(
          duration: AppMotion.fast,
          style: DefaultTextStyle.of(context).style.copyWith(fontWeight: FontWeight.w700, color: warn ? c.bad : c.good),
          child: Text(pace, textAlign: TextAlign.center),
        ),
      ],
    );
  }
}

/// An amount that counts to each new value with the app's soft ease, never
/// past it.
class _Counting extends StatelessWidget {
  const _Counting({required this.value, required this.style});

  final int value;
  final TextStyle style;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(end: value.toDouble()),
        duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : AppMotion.enter,
        curve: AppMotion.ease,
        builder: (context, v, _) => Text(Money.format(v.round()), style: style),
      );
}

/// A 270 degree track opening at the bottom, filled clockwise to [value].
class _DialPainter extends CustomPainter {
  _DialPainter({
    required this.value,
    required this.colour,
    required this.glow,
    required this.glowFrom,
    required this.glowTo,
    required this.stretches,
    required this.marker,
    required this.track,
    required this.divider,
    required this.ink,
    required this.muted,
    required this.letters,
  });

  final double value;
  final Color colour, glow, track, divider, ink, muted;
  final double glowFrom, glowTo;
  final List<(double, double, String, bool)> stretches;
  final double? marker;
  final TextStyle letters;

  static const _start = math.pi * 0.75;
  static const _sweep = math.pi * 1.5;
  static const _stroke = 15.0;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = size.center(Offset.zero);
    final r = size.shortestSide / 2 - 22;
    final rect = Rect.fromCircle(center: centre, radius: r);
    Offset at(double f, double radius) => centre + Offset(math.cos(_start + _sweep * f), math.sin(_start + _sweep * f)) * radius;
    Paint stroke(Color colour, [double width = _stroke]) => Paint()
      ..color = colour
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, _start, _sweep, false, stroke(track));
    // The overshoot past a full dial is not drawn; the spring settles back.
    final shown = value.clamp(0.0, 1.0);
    if (shown > 0.003) canvas.drawArc(rect, _start, _sweep * shown, false, stroke(colour));
    if (glowTo - glowFrom > 0.003) canvas.drawArc(rect, _start + _sweep * glowFrom, _sweep * (glowTo - glowFrom), false, stroke(glow));

    // A day squeezed off the end has no stretch to sit on.
    for (final (from, to, letter, today) in stretches.where((s) => s.$2 > s.$1)) {
      if (to < 1) canvas.drawLine(at(to, r - 9), at(to, r + 9), Paint()..color = divider..strokeWidth = 3);
      final text = TextPainter(
        text: TextSpan(text: letter, style: letters.copyWith(color: today ? ink : muted, fontWeight: today ? FontWeight.w800 : FontWeight.w600)),
        textDirection: TextDirection.ltr,
      )..layout();
      text.paint(canvas, at((from + to) / 2, r - 22) - Offset(text.width / 2, text.height / 2));
    }

    if (marker != null) {
      final m = at(marker!, r);
      canvas.drawCircle(m, 6.5, Paint()..color = divider);
      canvas.drawCircle(m, 6.5, stroke(ink, 2.5));
    }
  }

  @override
  bool shouldRepaint(_DialPainter old) =>
      old.value != value || old.colour != colour || old.glow != glow || old.glowFrom != glowFrom || old.glowTo != glowTo || old.marker != marker || !listEquals(old.stretches, stretches) || old.letters != letters;
}
