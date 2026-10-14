import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/money/money.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

enum DayStatus { kept, over, today, ahead }

class WeekDay {
  const WeekDay({required this.date, required this.label, required this.spent, required this.status});

  final DateTime date;
  final String label;
  final int spent;
  final DayStatus status;
}

/// Seven segments, Monday first, coloured by how each day went, with the
/// week's flexible spending against the cap in the middle.
class WeeklyRing extends StatelessWidget {
  const WeeklyRing({super.key, required this.days, required this.spent, required this.cap});

  final List<WeekDay> days;
  final int spent;
  final int cap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final left = cap - spent;
    final colours = {DayStatus.kept: c.good, DayStatus.over: c.bad, DayStatus.today: c.primary, DayStatus.ahead: c.line};
    return Semantics(
      label: 'This week ${Money.format(spent)} of ${Money.format(cap)} spent. '
          '${left >= 0 ? '${Money.format(left)} left' : '${Money.format(-left)} over'}.',
      excludeSemantics: true,
      child: Row(
        children: [
          SizedBox.square(
            dimension: 132,
            child: CustomPaint(
              painter: _RingPainter([for (final d in days) colours[d.status]!], todayIndex: days.indexWhere((d) => d.status == DayStatus.today)),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FittedBox(
                      child: Text(Money.format(spent), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, fontFeatures: [FontFeature.tabularFigures()])),
                    ),
                    Text('of ${Money.formatWhole(cap)}', style: TextStyle(fontSize: 12, color: c.muted)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.l),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final d in days.where((d) => d.status != DayStatus.ahead))
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs + 2),
                    child: Row(
                      children: [
                        Container(width: 10, height: 10, decoration: BoxDecoration(color: colours[d.status], shape: BoxShape.circle)),
                        const SizedBox(width: AppSpacing.s),
                        Expanded(
                          child: Text(
                            '${d.label}  ${d.status == DayStatus.today && d.spent == 0 ? 'today' : Money.format(d.spent)}',
                            style: const TextStyle(fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  left >= 0 ? '${Money.format(left)} left this week' : '${Money.format(-left)} over this week',
                  style: TextStyle(fontWeight: FontWeight.w700, color: left >= 0 ? c.good : c.bad),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.colours, {required this.todayIndex});

  final List<Color> colours;
  final int todayIndex;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 11.0;
    const gap = 0.14;
    final rect = Offset.zero & size;
    final arcRect = rect.deflate(stroke / 2 + 2);
    final sweep = 2 * math.pi / colours.length;
    for (var i = 0; i < colours.length; i++) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = i == todayIndex ? colours[i].withValues(alpha: 0.45) : colours[i];
      canvas.drawArc(arcRect, -math.pi / 2 + i * sweep + gap / 2, sweep - gap, false, paint);
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.todayIndex != todayIndex || !_sameColours(old.colours);

  bool _sameColours(List<Color> other) => other.length == colours.length && [for (var i = 0; i < colours.length; i++) other[i] == colours[i]].every((x) => x);
}
