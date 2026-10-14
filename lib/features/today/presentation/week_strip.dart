import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/money/money.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/soft.dart';

enum DayStatus { kept, over, today, ahead }

class WeekDay {
  const WeekDay({required this.date, required this.label, required this.spent, required this.planned, required this.status});

  final DateTime date;
  final String label;
  final int spent;
  final int planned;
  final DayStatus status;
}

/// The week against its allowance: one bar for the whole week, then a column
/// per day against that day's plan. Lengths are proportional to money, so a
/// bigger spend always looks bigger, and every state also has words.
class WeekStrip extends StatelessWidget {
  const WeekStrip({super.key, required this.days, required this.spent, required this.cap});

  final List<WeekDay> days;
  final int spent;
  final int cap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final left = cap - spent;
    final over = days.where((d) => d.status == DayStatus.over).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(Money.format(spent), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.5, fontFeatures: [FontFeature.tabularFigures()])),
            const SizedBox(width: AppSpacing.s),
            Expanded(child: Text('of ${Money.formatWhole(cap)} this week', style: TextStyle(color: c.muted))),
          ],
        ),
        const SizedBox(height: AppSpacing.s),
        Semantics(
          label: '${Money.format(spent)} of ${Money.format(cap)} spent this week',
          excludeSemantics: true,
          child: SoftMeter(value: cap == 0 ? (spent > 0 ? 1 : 0) : spent / cap, color: left >= 0 ? c.primary : c.bad),
        ),
        const SizedBox(height: AppSpacing.s),
        Text(
          left >= 0 ? '${Money.format(left)} left this week' : '${Money.format(-left)} over this week',
          style: TextStyle(fontWeight: FontWeight.w700, color: left >= 0 ? c.good : c.bad),
        ),
        const SizedBox(height: AppSpacing.l),
        _DayColumns(days: days),
        const SizedBox(height: AppSpacing.s),
        Text(
          over == 0 ? 'Every day so far within its plan' : '$over ${over == 1 ? 'day' : 'days'} over its plan',
          style: TextStyle(color: c.muted, fontSize: 13),
        ),
      ],
    );
  }
}

class _DayColumns extends StatelessWidget {
  const _DayColumns({required this.days});

  final List<WeekDay> days;

  static const _height = 64.0;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final top = math.max(1, days.map((d) => math.max(d.spent, d.planned)).fold(0, math.max));
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final (i, d) in days.indexed) ...[
          if (i > 0) const SizedBox(width: AppSpacing.s),
          Expanded(
            child: Semantics(
              label: '${d.label}, ${Money.format(d.spent)} of ${Money.format(d.planned)} planned, ${switch (d.status) {
                DayStatus.kept => 'within plan',
                DayStatus.over => 'over plan',
                DayStatus.today => 'today',
                DayStatus.ahead => 'to come',
              }}',
              excludeSemantics: true,
              child: Column(
                children: [
                  SizedBox(
                    height: _height,
                    child: CustomPaint(
                      size: const Size.fromHeight(_height),
                      painter: _DayPainter(
                        share: d.spent / top,
                        plan: d.planned / top,
                        fill: switch (d.status) {
                          DayStatus.kept => c.good,
                          DayStatus.over => c.bad,
                          DayStatus.today => c.primary,
                          DayStatus.ahead => c.well,
                        },
                        track: c.well,
                        mark: c.muted,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    d.label.substring(0, 1),
                    style: TextStyle(
                      fontSize: 12,
                      color: d.status == DayStatus.today ? c.ink : c.muted,
                      fontWeight: d.status == DayStatus.today ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// A rounded track with the day's spend filled from the bottom and a short
/// mark at the height of its plan.
class _DayPainter extends CustomPainter {
  _DayPainter({required this.share, required this.plan, required this.fill, required this.track, required this.mark});

  final double share;
  final double plan;
  final Color fill, track, mark;

  @override
  void paint(Canvas canvas, Size size) {
    final r = Radius.circular(size.width / 2.5);
    canvas.drawRRect(RRect.fromRectAndRadius(Offset.zero & size, r), Paint()..color = track);
    if (share > 0) {
      final h = math.max(size.width / 2, size.height * share.clamp(0, 1));
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, size.height - h, size.width, h), r), Paint()..color = fill);
    }
    if (plan > 0) {
      final y = size.height - size.height * plan.clamp(0, 1);
      canvas.drawLine(Offset(-2, y), Offset(size.width + 2, y), Paint()
        ..color = mark
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round);
    }
  }

  @override
  bool shouldRepaint(_DayPainter old) => old.share != share || old.plan != plan || old.fill != fill;
}
