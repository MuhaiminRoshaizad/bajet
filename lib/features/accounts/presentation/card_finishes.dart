import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../domain/account_models.dart';

/// Whether a finish catches the light differently as the card tilts, so it
/// must be repainted when the tilt changes. The rest are painted once.
bool finishMoves(CardFinish finish) => finish == CardFinish.mirror || finish == CardFinish.pearl;

/// A card's finish over its colour. [tilt], from -1 to 1, is how far the card
/// is turned, from swiping or a finger dragged over it; only the mirror and
/// pearl finishes follow it.
class FinishPainter extends CustomPainter {
  const FinishPainter(this.finish, {this.tilt = 0});

  final CardFinish finish;
  final double tilt;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    switch (finish) {
      case CardFinish.matte:
        _glow(canvas, rect, 0.07);
      case CardFinish.gloss:
        canvas.drawRect(
          rect,
          Paint()
            ..shader = const LinearGradient(
              begin: Alignment(-1, -0.4),
              end: Alignment(1, 0.4),
              colors: [Color(0x00FFFFFF), Color(0x4DFFFFFF), Color(0x00FFFFFF)],
              stops: [0.28, 0.40, 0.54],
            ).createShader(rect),
        );
        _glow(canvas, rect, 0.14);
      case CardFinish.mirror:
        // Polished metal: a bright band with darker metal either side, which
        // slides across as the card turns.
        final p = 0.5 + 0.35 * tilt.clamp(-1.0, 1.0);
        canvas.drawRect(
          rect,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: const [Color(0x1AFFFFFF), Color(0x38000000), Color(0x8CFFFFFF), Color(0x33000000), Color(0x24FFFFFF)],
              stops: [0, math.max(0.01, p - 0.2), p, math.min(0.99, p + 0.14), 1],
            ).createShader(rect),
        );
      case CardFinish.pearl:
        // A milky veil with a soft shimmer, pink to blue, that drifts with
        // the tilt.
        canvas.drawRect(rect, Paint()..color = const Color(0x14FFFFFF));
        canvas.drawRect(
          rect,
          Paint()
            ..shader = RadialGradient(
              center: Alignment(0.7 * tilt.clamp(-1.0, 1.0), -0.7),
              radius: 1.2,
              colors: const [Color(0x59FFFFFF), Color(0x33FFD6EC), Color(0x2ECDE7FF), Color(0x00FFFFFF)],
              stops: const [0, 0.35, 0.7, 1],
            ).createShader(rect),
        );
      case CardFinish.frosted:
        // Fine frost, lighter at the top, with an etched edge.
        canvas.drawRect(rect, Paint()..shader = _tile(_frost));
        canvas.drawRect(
          rect,
          Paint()
            ..shader = const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x2EFFFFFF), Color(0x0AFFFFFF), Color(0x00FFFFFF)],
              stops: [0, 0.4, 1],
            ).createShader(rect),
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect.deflate(1), const Radius.circular(15)),
          Paint()
            ..color = const Color(0x59FFFFFF)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
      case CardFinish.guilloche:
        // Engraved waves, like the pattern on a banknote.
        final line = Paint()
          ..color = const Color(0x21FFFFFF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8;
        for (var k = -6; k < 26; k++) {
          final path = Path();
          for (var x = 0.0; x <= size.width; x += 3) {
            final y = k * size.height / 18 +
                math.sin(x / size.width * math.pi * 3 + k * 0.5) * size.height * 0.09 +
                math.sin(x / size.width * math.pi * 7) * size.height * 0.02;
            x == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
          }
          canvas.drawPath(path, line);
        }
        _glow(canvas, rect, 0.08);
      case CardFinish.leather || CardFinish.suede:
        break;
    }
  }

  static void _glow(Canvas canvas, Rect rect, double strength) => canvas.drawRect(
        rect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white.withValues(alpha: strength), Colors.transparent, Colors.black.withValues(alpha: 0.12)],
          ).createShader(rect),
      );

  @override
  bool shouldRepaint(FinishPainter old) => old.finish != finish || (finishMoves(finish) && old.tilt != tilt);
}

/// Suede: a soft brushed nap, darker in the middle where it is held, with
/// the wallet's pocket lip and stitching.
class SuedePainter extends CustomPainter {
  const SuedePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..shader = _tile(_nap));
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(0, 0.15),
          radius: 0.75,
          colors: [Color(0x2E000000), Color(0x00000000)],
        ).createShader(rect),
    );
    paintWalletEdge(canvas, size);
  }

  @override
  bool shouldRepaint(SuedePainter old) => false;
}

/// The darker lip of the pocket the bills come out of, and the stitching
/// round the edge, shared by every wallet.
void paintWalletEdge(Canvas canvas, Size size) {
  final lip = Rect.fromLTWH(0, 0, size.width, size.height * 0.11);
  canvas.drawRRect(
    RRect.fromRectAndCorners(lip, topLeft: const Radius.circular(16), topRight: const Radius.circular(16)),
    Paint()
      ..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x47000000), Color(0x14000000)])
          .createShader(lip),
  );
  canvas.drawLine(lip.bottomLeft, lip.bottomRight, Paint()..color = const Color(0x1AFFFFFF));
  final stitch = Paint()
    ..color = const Color(0x42FFFFFF)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.4;
  final path = Path()..addRRect(RRect.fromRectAndRadius((Offset.zero & size).deflate(7), const Radius.circular(11)));
  for (final metric in path.computeMetrics()) {
    for (var d = 0.0; d < metric.length; d += 8) {
      canvas.drawPath(metric.extractPath(d, d + 4), stitch);
    }
  }
}

ImageShader _tile(ui.Image image) => ImageShader(image, TileMode.repeated, TileMode.repeated, Matrix4.identity().storage);

/// Textures made once, the first time a card needs them, then shared by
/// every card: a small square of specks, tiled.
final ui.Image _frost = _texture(seed: 3, (canvas, random) {
  final speck = Paint();
  for (var i = 0; i < 1400; i++) {
    speck.color = Colors.white.withValues(alpha: random.nextDouble() * 0.08);
    canvas.drawRect(Rect.fromLTWH(random.nextDouble() * _side, random.nextDouble() * _side, 1.2, 1.2), speck);
  }
});

final ui.Image _nap = _texture(seed: 5, (canvas, random) {
  final fibre = Paint();
  for (var i = 0; i < 3000; i++) {
    fibre.color = (random.nextBool() ? Colors.white : Colors.black).withValues(alpha: random.nextDouble() * 0.05);
    canvas.drawRect(Rect.fromLTWH(random.nextDouble() * _side, random.nextDouble() * _side, 1, 2.5), fibre);
  }
});

const _side = 96.0;

ui.Image _texture(void Function(Canvas canvas, math.Random random) draw, {required int seed}) {
  final recorder = ui.PictureRecorder();
  draw(Canvas(recorder), math.Random(seed));
  final picture = recorder.endRecording();
  final image = picture.toImageSync(_side.toInt(), _side.toInt());
  picture.dispose();
  return image;
}
