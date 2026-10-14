import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/dates/dates.dart';
import '../../../core/money/money.dart';
import '../../../core/theme/app_colors.dart';
import '../domain/projection.dart';

/// The projected balance from today to buy day. Salary days step up, bills
/// dip, and the drop on buy day is drawn as its own dotted step down to what
/// is left. The dotted line across is the buffer.
class RunwayChart extends StatelessWidget {
  const RunwayChart({super.key, required this.days, required this.buffer, required this.onTrack});

  final List<ProjectedDay> days;
  final int buffer;
  final bool onTrack;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final last = days.last;
    return Semantics(
      label: 'Projected balance from ${Money.format(days.first.balance)} today to ${Money.format(last.balance)} on ${Dates.full(last.date)}',
      excludeSemantics: true,
      child: AspectRatio(
        aspectRatio: 1.75,
        child: CustomPaint(
          painter: _RunwayPainter(
            days: days,
            buffer: buffer,
            line: c.primary,
            fill: c.primary.withValues(alpha: 0.10),
            bufferColour: c.keep,
            endColour: onTrack ? c.keep : c.bad,
            labels: c.muted,
            card: c.card,
            ink: c.ink,
          ),
        ),
      ),
    );
  }
}

class _RunwayPainter extends CustomPainter {
  _RunwayPainter({
    required this.days,
    required this.buffer,
    required this.line,
    required this.fill,
    required this.bufferColour,
    required this.endColour,
    required this.labels,
    required this.card,
    required this.ink,
  });

  final List<ProjectedDay> days;
  final int buffer;
  final Color line, fill, bufferColour, endColour, labels, card, ink;

  static const _top = 22.0, _bottom = 22.0, _side = 6.0;

  @override
  void paint(Canvas canvas, Size size) {
    final peak = days.map((d) => d.balanceBeforeGoals).fold(buffer, math.max) * 1.1;
    final top = peak <= 0 ? 1.0 : peak.toDouble();
    double x(int i) => _side + (size.width - 2 * _side) * (days.length == 1 ? 0 : i / (days.length - 1));
    double y(int v) => _top + (size.height - _top - _bottom) * (1 - math.max(0, v) / top);
    final lastIndex = days.length - 1;

    final path = Path()..moveTo(x(0), y(days[0].balance));
    for (var i = 1; i < days.length; i++) {
      path.lineTo(x(i), y(i == lastIndex ? days[i].balanceBeforeGoals : days[i].balance));
    }
    final area = Path.from(path)
      ..lineTo(x(lastIndex), y(0))
      ..lineTo(x(0), y(0))
      ..close();
    canvas.drawPath(area, Paint()..color = fill);

    _dotted(canvas, Offset(_side, y(buffer)), Offset(size.width - _side, y(buffer)), bufferColour);
    _text(canvas, 'Buffer ${Money.formatWhole(buffer)}', Offset(_side + 2, y(buffer) - 16), bufferColour);

    canvas.drawPath(
      path,
      Paint()
        ..color = line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeJoin = StrokeJoin.round,
    );
    _dotted(canvas, Offset(x(lastIndex), y(days[lastIndex].balanceBeforeGoals)), Offset(x(lastIndex), y(days[lastIndex].balance)), line);

    canvas.drawCircle(Offset(x(lastIndex), y(days[lastIndex].balance)), 6, Paint()..color = endColour);
    canvas.drawCircle(Offset(x(lastIndex), y(days[lastIndex].balance)), 6, Paint()
      ..color = card
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3);
    canvas.drawCircle(Offset(x(0), y(days[0].balance)), 5, Paint()..color = card);
    canvas.drawCircle(Offset(x(0), y(days[0].balance)), 5, Paint()
      ..color = line
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5);
    _text(canvas, 'Now', Offset(x(0) + 2, y(days[0].balance) - 20), ink);

    // Month initials along the bottom, at each first of the month.
    for (var i = 1; i < days.length; i++) {
      if (days[i].date.day == 1) _text(canvas, Dates.monthShort(days[i].date), Offset(x(i) - 9, size.height - 16), labels);
    }
  }

  void _dotted(Canvas canvas, Offset from, Offset to, Color colour) {
    final paint = Paint()
      ..color = colour
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final length = (to - from).distance;
    if (length == 0) return;
    final step = (to - from) / length;
    for (var d = 0.0; d < length; d += 7) {
      canvas.drawLine(from + step * d, from + step * math.min(d + 1, length), paint);
    }
  }

  void _text(Canvas canvas, String text, Offset at, Color colour) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: colour, fontSize: 11, fontFamily: 'Figtree')),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, at);
  }

  @override
  bool shouldRepaint(_RunwayPainter old) => old.days != days || old.buffer != buffer || old.endColour != endColour || old.line != line;
}
