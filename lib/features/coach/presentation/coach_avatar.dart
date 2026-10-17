import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../domain/coach_settings.dart';

/// Whether coaches breathe, blink and think in a loop. Tests turn it off,
/// since a loop that never ends never lets a screen settle.
final coachIdleMotionProvider = Provider<bool>((ref) => true);

/// What the coach's face is doing.
enum CoachMood { idle, thinking, happy, concerned, cheer, hello, stare }

/// The coach, drawn in code: the titanium orb or one of three finance
/// people. Every change of [mood] starts with a jelly wobble and morphs the
/// face rather than snapping it; at rest it breathes and blinks, and it
/// settles still after a minute with nothing happening. With [animate] off,
/// as for the small faces beside old replies, it is a still picture.
class CoachAvatar extends StatefulWidget {
  const CoachAvatar({super.key, required this.face, this.mood = CoachMood.idle, this.size = 40, this.animate = true, this.idle = true, this.onTap});

  final CoachFace face;
  final CoachMood mood;
  final double size;
  final bool animate;

  /// Breathing, blinking and the thinking loop; mood changes still move
  /// without it.
  final bool idle;
  final VoidCallback? onTap;

  @override
  State<CoachAvatar> createState() => _CoachAvatarState();
}

/// A looser spring than the app's own, so the face wobbles once before it
/// settles, like jelly.
final _jellySpring = SpringDescription.withDampingRatio(mass: 1, stiffness: 220, ratio: 0.42);

class _CoachAvatarState extends State<CoachAvatar> with TickerProviderStateMixin {
  late final _morph = AnimationController(vsync: this, duration: const Duration(milliseconds: 420), value: 1);
  late final _jelly = AnimationController.unbounded(vsync: this, value: 1);
  late final _hop = AnimationController.unbounded(vsync: this, value: 1);
  late final _shake = AnimationController(vsync: this, duration: const Duration(milliseconds: 520), value: 1);
  late final _blink = AnimationController(vsync: this, duration: const Duration(milliseconds: 200), value: 1);
  late final _breathe = AnimationController(vsync: this, duration: const Duration(milliseconds: 3200));
  late final _orbit = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
  late final _spark = AnimationController(vsync: this, duration: const Duration(milliseconds: 700), value: 1);

  /// How long the surprised hello holds before the smile comes back.
  late final _hello = AnimationController(vsync: this, duration: const Duration(milliseconds: 520))
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed && mounted) setState(() => _react(CoachMood.idle));
    });
  late _Expression _from = _Expression.of(widget.mood), _to = _from;
  var _hopHeight = 0.0;
  Timer? _blinkTimer, _settleTimer;
  final _random = math.Random();

  bool get _moving => widget.animate && !(MediaQuery.maybeDisableAnimationsOf(context) ?? false);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _wake();
  }

  @override
  void didUpdateWidget(CoachAvatar old) {
    super.didUpdateWidget(old);
    if (old.mood != widget.mood || old.face != widget.face) _react(widget.mood);
  }

  void _react(CoachMood mood) {
    _from = _Expression.lerp(_from, _to, Curves.easeOutBack.transform(_morph.value));
    _to = _Expression.of(mood);
    if (!_moving) {
      _morph.value = 1;
      return;
    }
    _morph.forward(from: 0);
    _jelly.animateWith(SpringSimulation(_jellySpring, 0, 1, 0, snapToEnd: true));
    switch (mood) {
      case CoachMood.happy:
        _jump(5);
      case CoachMood.cheer:
        _jump(9);
        _spark.forward(from: 0);
      case CoachMood.hello:
        _jump(7);
        // Surprise, then back to a smile.
        _hello.forward(from: 0);
      case CoachMood.concerned:
        _shake.forward(from: 0);
      case CoachMood.idle || CoachMood.thinking || CoachMood.stare:
        break;
    }
    _wake();
  }

  void _jump(double height) {
    _hopHeight = height;
    _hop.animateWith(SpringSimulation(AppMotion.spring, 0, 1, 0, snapToEnd: true));
  }

  /// Starts breathing and blinking, and settles still after a minute.
  void _wake() {
    if (!_moving || !widget.idle) {
      _breathe.stop();
      _orbit.stop();
      return;
    }
    if (!_breathe.isAnimating) _breathe.repeat();
    if (_to.thinking) {
      if (!_orbit.isAnimating) _orbit.repeat();
    } else {
      _orbit.stop();
    }
    _blinkTimer ??= _scheduleBlink();
    _settleTimer?.cancel();
    _settleTimer = Timer(const Duration(minutes: 1), () {
      _breathe.stop();
      _blinkTimer?.cancel();
      _blinkTimer = null;
    });
  }

  Timer _scheduleBlink() => Timer(Duration(milliseconds: 3000 + _random.nextInt(2000)), () {
        // A stare holds its gaze; that is the joke.
        if (mounted && widget.mood != CoachMood.stare) _blink.forward(from: 0);
        _blinkTimer = mounted ? _scheduleBlink() : null;
      });

  @override
  void dispose() {
    _blinkTimer?.cancel();
    _settleTimer?.cancel();
    for (final c in [_morph, _jelly, _hop, _shake, _blink, _breathe, _orbit, _spark, _hello]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final picture = RepaintBoundary(
      child: CustomPaint(
        size: Size.square(widget.size),
        painter: _AvatarPainter(
          face: widget.face,
          colors: c,
          from: _from,
          to: _to,
          morph: _morph,
          jelly: _jelly,
          hop: _hop,
          hopHeight: () => _hopHeight,
          shake: _shake,
          blink: _blink,
          breathe: _breathe,
          orbit: _orbit,
          spark: _spark,
        ),
      ),
    );
    return Semantics(
      label: '${widget.face.label}, your money coach',
      button: widget.onTap != null,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: widget.onTap == null
            ? null
            : () {
                setState(() => _react(CoachMood.hello));
                widget.onTap!();
              },
        child: picture,
      ),
    );
  }
}

/// A mouth as two quadratic curves, there and back: equal controls draw a
/// line, different ones an open mouth, so any two can be morphed.
class _Mouth {
  const _Mouth(this.start, this.top, this.end, this.bottom);

  final Offset start, top, end, bottom;

  static _Mouth lerp(_Mouth a, _Mouth b, double t) =>
      _Mouth(Offset.lerp(a.start, b.start, t)!, Offset.lerp(a.top, b.top, t)!, Offset.lerp(a.end, b.end, t)!, Offset.lerp(a.bottom, b.bottom, t)!);

  _Mouth shift(Offset by) => _Mouth(start + by, top + by, end + by, bottom + by);
}

/// Everything about a face that changes with the mood, in the person's
/// 100-unit box.
class _Expression {
  const _Expression(this.mouth, this.brow, this.look, this.blush, this.tilt, {this.thinking = false});

  final _Mouth mouth;

  /// How far the brows lift, from worried (-1) through calm (0) to raised (1).
  final double brow;
  final Offset look;
  final double blush;

  /// The head's lean, in degrees.
  final double tilt;
  final bool thinking;

  static const _smile = _Mouth(Offset(44.5, 53.2), Offset(50, 57.4), Offset(55.5, 53.2), Offset(50, 57.4));
  static const _grin = _Mouth(Offset(43.5, 52.4), Offset(50, 60.5), Offset(56.5, 52.4), Offset(50, 55.2));
  static const _flat = _Mouth(Offset(45.5, 54.4), Offset(50, 55), Offset(54.5, 54.4), Offset(50, 55));
  static const _worry = _Mouth(Offset(45.5, 55.6), Offset(50, 52.6), Offset(54.5, 55.6), Offset(50, 52.6));
  static const _o = _Mouth(Offset(48, 54.5), Offset(50, 52), Offset(52, 54.5), Offset(50, 57));

  static _Expression of(CoachMood mood) => switch (mood) {
        CoachMood.idle => const _Expression(_smile, 0, Offset.zero, 0, 0),
        CoachMood.thinking => const _Expression(_flat, 1, Offset(1.6, -1.6), 0, 4, thinking: true),
        CoachMood.happy || CoachMood.cheer => const _Expression(_grin, 1, Offset(0, -0.4), 1, 0),
        CoachMood.concerned => const _Expression(_worry, -1, Offset(-0.6, 0.6), 0, 0),
        CoachMood.hello => const _Expression(_o, 1, Offset.zero, 0.6, 0),
        CoachMood.stare => const _Expression(_flat, 0, Offset.zero, 0, 0),
      };

  static _Expression lerp(_Expression a, _Expression b, double t) => _Expression(
        _Mouth.lerp(a.mouth, b.mouth, t),
        lerpDouble(a.brow, b.brow, t)!,
        Offset.lerp(a.look, b.look, t)!,
        lerpDouble(a.blush, b.blush, t)!,
        lerpDouble(a.tilt, b.tilt, t)!,
        thinking: t < 0.5 ? a.thinking : b.thinking,
      );
}

enum _Hair { tudung, short, bob }

/// A finance person's fixed colours: drawn artwork, the same in light and
/// dark like a card's face, on a background from the theme.
class _Person {
  const _Person({required this.style, required this.background, required this.skin, required this.skinShade, required this.cloth, required this.cloth2, this.hair, this.scarf, this.tie, this.badge, this.glasses = false});

  final _Hair style;
  final Tint background;
  final Color skin, skinShade, cloth, cloth2;
  final Color? hair, scarf, tie, badge;
  final bool glasses;
}

const _aina = _Person(style: _Hair.tudung, background: Tint.sky, skin: Color(0xFFC98E6A), skinShade: Color(0xFFB47858), cloth: Color(0xFFEFE4D2), cloth2: Color(0xFFD8C8B0), scarf: Color(0xFF5F86A8), badge: Color(0xFF2E5D7E));
const _hafiz = _Person(style: _Hair.short, background: Tint.sage, skin: Color(0xFFB07850), skinShade: Color(0xFF986444), cloth: Color(0xFF26384F), cloth2: Color(0xFF1B2A3D), hair: Color(0xFF1F1A17), tie: Color(0xFFD98A3A), glasses: true);
const _mei = _Person(style: _Hair.bob, background: Tint.apricot, skin: Color(0xFFF0C8A6), skinShade: Color(0xFFDCAE8A), cloth: Color(0xFF7C9A82), cloth2: Color(0xFF64806A), hair: Color(0xFF3A2A22));

const _ink = Color(0xFF2A1D14);
const _lips = Color(0xFF7A3B2E);
const _graphite = Color(0xFF121418);

class _AvatarPainter extends CustomPainter {
  _AvatarPainter({
    required this.face,
    required this.colors,
    required this.from,
    required this.to,
    required this.morph,
    required this.jelly,
    required this.hop,
    required this.hopHeight,
    required this.shake,
    required this.blink,
    required this.breathe,
    required this.orbit,
    required this.spark,
  }) : super(repaint: Listenable.merge([morph, jelly, hop, shake, blink, breathe, orbit, spark]));

  final CoachFace face;
  final AppColors colors;
  final _Expression from, to;
  final Animation<double> morph, jelly, hop, shake, blink, breathe, orbit, spark;
  final double Function() hopHeight;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 100);
    final e = _Expression.lerp(from, to, Curves.easeOutBack.transform(morph.value.clamp(0, 1)));
    final squash = 1 - jelly.value;
    final lift = math.sin(hop.value.clamp(0, 1) * math.pi) * hopHeight();
    final wobble = shake.isAnimating ? math.sin(shake.value * math.pi * 4) * 6 * (1 - shake.value) : 0.0;
    final breath = math.sin(breathe.value * math.pi * 2) * 0.9;
    final eyeOpen = 1 - math.sin(blink.value * math.pi) * 0.9;
    if (face == CoachFace.bajety) {
      _orb(canvas, e, squash: squash, lift: lift + breath * 2.4, wobble: wobble, eyeOpen: eyeOpen);
    } else {
      _person(canvas, switch (face) { CoachFace.aina => _aina, CoachFace.hafiz => _hafiz, _ => _mei }, e,
          squash: squash, lift: lift, wobble: wobble, breath: breath, eyeOpen: eyeOpen);
    }
  }

  /// The body squashes about its bottom: wide and short, then springing
  /// through tall and thin.
  void _squash(Canvas canvas, double squash, Offset pivot) {
    canvas.translate(pivot.dx, pivot.dy);
    canvas.scale(1 + squash * 0.07, 1 - squash * 0.1);
    canvas.translate(-pivot.dx, -pivot.dy);
  }

  void _rotate(Canvas canvas, double degrees, Offset pivot) {
    canvas.translate(pivot.dx, pivot.dy);
    canvas.rotate(degrees * math.pi / 180);
    canvas.translate(-pivot.dx, -pivot.dy);
  }

  void _orb(Canvas canvas, _Expression e, {required double squash, required double lift, required double wobble, required double eyeOpen}) {
    final fill = Paint();
    canvas.drawOval(const Rect.fromLTRB(26, 93.5, 74, 100.5), fill..color = colors.shade.withValues(alpha: 0.7));
    canvas.save();
    canvas.translate(0, -lift);
    _squash(canvas, squash, const Offset(50, 92));
    _rotate(canvas, wobble + e.tilt * 0.5, const Offset(50, 50));
    const body = Rect.fromLTRB(8, 8, 92, 92);
    canvas.drawOval(
      body,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.28, -0.4),
          radius: 0.78,
          colors: [Color(0xFFFFFFFF), Color(0xFFD8DBDF), Color(0xFF9AA0A8), Color(0xFF5F656D)],
          stops: [0, 0.35, 0.8, 1],
        ).createShader(body),
    );
    canvas.drawOval(body.deflate(0.8), Paint()..color = const Color(0x8CFFFFFF)..style = PaintingStyle.stroke..strokeWidth = 1.2);
    canvas.save();
    _rotate(canvas, -28, const Offset(35, 28));
    canvas.drawOval(const Rect.fromLTRB(23, 21.5, 47, 34.5), fill..color = const Color(0xB3FFFFFF));
    canvas.restore();
    if (e.blush > 0) {
      fill.color = const Color(0xFFFF9E8A).withValues(alpha: 0.45 * e.blush);
      canvas.drawOval(const Rect.fromLTRB(23, 54.6, 35, 61.4), fill);
      canvas.drawOval(const Rect.fromLTRB(65, 54.6, 77, 61.4), fill);
    }
    // The orb's face is twice the size of a person's, so it moves twice as far.
    final look = e.look * 2;
    for (final x in [33.0, 58.0]) {
      final eye = Rect.fromLTWH(x + look.dx, 38 + look.dy + 6.5 * (1 - eyeOpen), 9, 13 * eyeOpen);
      canvas.drawRRect(RRect.fromRectAndRadius(eye, const Radius.circular(4.5)), fill..color = _graphite);
      if (eyeOpen > 0.5) canvas.drawCircle(Offset(x + 6.5 + look.dx, 41.5 + look.dy), 1.6, fill..color = const Color(0xE6FFFFFF));
    }
    // The mouth is drawn from the person's, scaled up about the face's middle.
    final m = e.mouth;
    Offset big(Offset p) => Offset(50 + (p.dx - 50) * 2.2, 62 + (p.dy - 54.5) * 2.2);
    _drawMouth(canvas, _Mouth(big(m.start), big(m.top), big(m.end), big(m.bottom)), _graphite, 3.6);
    canvas.restore();
    if (e.thinking) {
      canvas.save();
      _rotate(canvas, orbit.value * 360, const Offset(50, 50));
      canvas.drawCircle(const Offset(50, 3), 3.2, fill..color = const Color(0xFFD8DBDF));
      canvas.drawCircle(const Offset(97, 50), 2.4, fill..color = colors.primary);
      canvas.restore();
    }
    _sparkles(canvas, fill);
  }

  void _person(Canvas canvas, _Person p, _Expression e,
      {required double squash, required double lift, required double wobble, required double breath, required double eyeOpen}) {
    final fill = Paint();
    canvas.save();
    canvas.clipPath(Path()..addOval(const Rect.fromLTWH(0, 0, 100, 100)));
    canvas.drawRect(const Rect.fromLTWH(0, 0, 100, 100), fill..color = colors.tintFill(p.background));
    canvas.translate(0, -lift - breath);
    _squash(canvas, squash, const Offset(50, 100));

    // Shoulders and clothes.
    canvas.drawPath(Path()..moveTo(12, 104)..quadraticBezierTo(14, 76, 50, 71)..quadraticBezierTo(86, 76, 88, 104)..close(), fill..color = p.cloth);
    final seam = Paint()..color = p.cloth2..style = PaintingStyle.stroke..strokeWidth = 2.2;
    if (p.style == _Hair.tudung) {
      canvas.drawLine(const Offset(36, 76), const Offset(44, 104), seam);
      canvas.drawLine(const Offset(64, 76), const Offset(56, 104), seam);
      canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(46, 88, 8, 6), const Radius.circular(1.5)), fill..color = p.badge!);
    } else {
      canvas.drawPath(Path()..moveTo(42.5, 71.5)..lineTo(50, 88)..lineTo(57.5, 71.5)..close(), fill..color = const Color(0xFFF6F4EF));
      if (p.tie != null) {
        canvas.drawPath(Path()..moveTo(48.6, 74)..lineTo(51.4, 74)..lineTo(53, 87)..lineTo(50, 91)..lineTo(47, 87)..close(), fill..color = p.tie!);
      } else {
        canvas.drawCircle(const Offset(50, 80), 1.4, fill..color = p.cloth2);
      }
      canvas.drawPath(Path()..moveTo(42.5, 71.5)..lineTo(50, 88)..lineTo(39, 104)..moveTo(57.5, 71.5)..lineTo(50, 88)..lineTo(61, 104), seam);
    }
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(45, 60, 10, 13), const Radius.circular(4)), fill..color = p.skinShade);

    // The head leans, wobbles and tilts about the neck.
    canvas.save();
    _rotate(canvas, e.tilt + wobble, const Offset(50, 66));
    if (p.style == _Hair.tudung) {
      canvas.drawPath(
        Path()
          ..moveTo(50, 18)
          ..cubicTo(30, 18, 25, 36, 27, 53)
          ..cubicTo(28, 66, 36, 74, 50, 76)
          ..cubicTo(64, 74, 72, 66, 73, 53)
          ..cubicTo(75, 36, 70, 18, 50, 18)
          ..close(),
        fill..color = p.scarf!,
      );
    } else if (p.style == _Hair.short) {
      for (final x in [33.0, 67.0]) {
        canvas.drawOval(Rect.fromCenter(center: Offset(x, 47), width: 5.2, height: 8), fill..color = p.skinShade);
      }
    } else {
      canvas.drawPath(
        Path()
          ..moveTo(30, 47)
          ..cubicTo(28, 26, 40, 18.5, 50, 18.5)
          ..cubicTo(60, 18.5, 72, 26, 70, 47)
          ..lineTo(71, 63)
          ..quadraticBezierTo(50, 69, 29, 63)
          ..close(),
        fill..color = p.hair!,
      );
    }
    final headRect = p.style == _Hair.tudung ? Rect.fromCenter(center: const Offset(50, 46), width: 31, height: 36) : Rect.fromCenter(center: const Offset(50, 45), width: 34, height: 40);
    canvas.drawOval(headRect, fill..color = p.skin);
    if (e.blush > 0) {
      fill.color = const Color(0xFFFF8F80).withValues(alpha: 0.5 * e.blush);
      canvas.drawOval(Rect.fromCenter(center: const Offset(40, 51), width: 7.2, height: 4), fill);
      canvas.drawOval(Rect.fromCenter(center: const Offset(60, 51), width: 7.2, height: 4), fill);
    }
    for (final x in [42.5, 57.5]) {
      canvas.drawOval(Rect.fromCenter(center: Offset(x, 44.6) + e.look, width: 3.8, height: 4.8 * eyeOpen), fill..color = _ink);
    }
    final brow = Paint()..color = _ink..style = PaintingStyle.stroke..strokeWidth = 1.5..strokeCap = StrokeCap.round;
    // Raised brows lift both ends; worried ones lift only the inner end.
    final up = math.max(0.0, e.brow) * 2, inner = math.max(0.0, -e.brow) * 2;
    canvas.drawPath(Path()..moveTo(38.5, 37.6 - up)..quadraticBezierTo(42.5, 35.6 - up - inner * 0.2, 46.5, 37.2 - up - inner), brow);
    canvas.drawPath(Path()..moveTo(53.5, 37.2 - up - inner)..quadraticBezierTo(57.5, 35.6 - up - inner * 0.2, 61.5, 37.6 - up), brow);
    canvas.drawPath(Path()..moveTo(50, 46.5)..quadraticBezierTo(48.6, 50.5, 50.4, 50.8), Paint()..color = p.skinShade..style = PaintingStyle.stroke..strokeWidth = 1.3..strokeCap = StrokeCap.round);
    _drawMouth(canvas, e.mouth, _lips, 1.8);
    if (p.glasses) {
      final frame = Paint()..color = const Color(0xFF2A2A2A)..style = PaintingStyle.stroke..strokeWidth = 1.4;
      canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(37, 40.5, 11, 8), const Radius.circular(3)), frame);
      canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(52, 40.5, 11, 8), const Radius.circular(3)), frame);
      canvas.drawLine(const Offset(48, 44), const Offset(52, 44), frame);
    }
    if (p.style == _Hair.tudung) {
      canvas.drawPath(
        Path()
          ..moveTo(27.5, 54)
          ..quadraticBezierTo(24, 82, 30, 100)
          ..lineTo(70, 100)
          ..quadraticBezierTo(76, 82, 72.5, 54)
          ..quadraticBezierTo(66, 72, 50, 75)
          ..quadraticBezierTo(34, 72, 27.5, 54)
          ..close(),
        fill..color = p.scarf!,
      );
      canvas.drawPath(
        Path()
          ..moveTo(33, 40)
          ..cubicTo(34, 27, 42, 22.5, 50, 22.5)
          ..cubicTo(58, 22.5, 66, 27, 67, 40)
          ..cubicTo(62, 31, 56, 28.5, 50, 28.5)
          ..cubicTo(44, 28.5, 38, 31, 33, 40)
          ..close(),
        fill,
      );
      canvas.drawCircle(const Offset(62, 68), 1.6, fill..color = const Color(0xE6F4F0E8));
    } else if (p.style == _Hair.short) {
      canvas.drawPath(
        Path()
          ..moveTo(33.4, 43)
          ..cubicTo(31, 27, 41, 20.5, 51, 20.5)
          ..cubicTo(62, 20.5, 69.5, 27.5, 67, 43)
          ..cubicTo(64.5, 35, 58.5, 31, 50, 31.5)
          ..cubicTo(42, 31.5, 36, 35, 33.4, 43)
          ..close(),
        fill..color = p.hair!,
      );
    } else {
      canvas.drawPath(
        Path()
          ..moveTo(33, 41)
          ..cubicTo(34, 28, 43, 23.5, 51, 24)
          ..cubicTo(59, 24.5, 66, 29, 67, 41)
          ..cubicTo(61, 34.5, 54, 32, 46, 33.5)
          ..cubicTo(40, 34.5, 36, 37.5, 33, 41)
          ..close(),
        fill..color = p.hair!,
      );
    }
    canvas.restore();
    canvas.restore();
    if (e.thinking) {
      // A thought bubble rising at the top right, each puff pulsing in turn.
      for (final (i, (centre, r)) in const [(Offset(76, 20), 2.4), (Offset(82, 13), 3.2), (Offset(89, 7), 4.0)].indexed) {
        final pulse = 0.35 + 0.65 * (0.5 + 0.5 * math.sin((orbit.value - i * 0.15) * math.pi * 2));
        canvas.drawCircle(centre, r, fill..color = Colors.white.withValues(alpha: pulse));
      }
    }
    _sparkles(canvas, fill);
  }

  void _drawMouth(Canvas canvas, _Mouth m, Color colour, double width) {
    final path = Path()
      ..moveTo(m.start.dx, m.start.dy)
      ..quadraticBezierTo(m.top.dx, m.top.dy, m.end.dx, m.end.dy)
      ..quadraticBezierTo(m.bottom.dx, m.bottom.dy, m.start.dx, m.start.dy);
    // How open it is decides how much of the inside is filled.
    final open = ((m.top.dy - m.bottom.dy).abs() / 6).clamp(0.0, 1.0);
    if (open > 0.05) canvas.drawPath(path, Paint()..color = colour.withValues(alpha: open));
    canvas.drawPath(path, Paint()..color = colour..style = PaintingStyle.stroke..strokeWidth = width..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round);
  }

  void _sparkles(Canvas canvas, Paint fill) {
    if (!spark.isAnimating) return;
    final shine = math.sin(spark.value * math.pi);
    canvas.save();
    canvas.translate(0, -6 * spark.value);
    for (final (centre, r) in const [(Offset(88, 22), 5.0), (Offset(13, 28), 3.6)]) {
      canvas.drawPath(_star(centre, r), fill..color = const Color(0xFFFFFFFF).withValues(alpha: shine));
    }
    canvas.restore();
  }

  Path _star(Offset c, double r) => Path()
    ..moveTo(c.dx, c.dy - r)
    ..lineTo(c.dx + r * 0.3, c.dy - r * 0.3)
    ..lineTo(c.dx + r, c.dy)
    ..lineTo(c.dx + r * 0.3, c.dy + r * 0.3)
    ..lineTo(c.dx, c.dy + r)
    ..lineTo(c.dx - r * 0.3, c.dy + r * 0.3)
    ..lineTo(c.dx - r, c.dy)
    ..lineTo(c.dx - r * 0.3, c.dy - r * 0.3)
    ..close();

  @override
  bool shouldRepaint(_AvatarPainter old) => old.face != face || old.from != from || old.to != to || old.colors != colors;
}
