import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';

/// The chat's send button. While the coach works the arrow folds away and
/// a small living sphere springs out of the button: a globe of light dust
/// turning in 3D, rings orbiting behind and in front of it with comets
/// running along them, and a core that pulses. When the reply lands the
/// sphere collapses in a ripple and the arrow springs back. With reduce
/// motion on, the sphere simply stands still.
class ThinkingSendButton extends StatefulWidget {
  const ThinkingSendButton({super.key, required this.thinking, required this.onSend, this.size = 52});

  final bool thinking;

  /// Null while sending is not possible; the arrow then greys.
  final VoidCallback? onSend;
  final double size;

  @override
  State<ThinkingSendButton> createState() => _ThinkingSendButtonState();
}

class _ThinkingSendButtonState extends State<ThinkingSendButton> with TickerProviderStateMixin {
  /// 0 is the arrow, 1 the sphere; driven by a spring, so it overshoots.
  late final _morph = AnimationController.unbounded(vsync: this, value: widget.thinking ? 1 : 0);

  /// The sphere's own clock: one 8 second loop.
  late final _loop = AnimationController(vsync: this, duration: const Duration(seconds: 8));

  /// The ripple left behind as the sphere folds back into the button.
  late final _ripple = AnimationController(vsync: this, duration: const Duration(milliseconds: 650), value: 1);

  var _pressed = false;

  bool get _still => MediaQuery.disableAnimationsOf(context);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.thinking && !_still && !_loop.isAnimating) _loop.repeat();
  }

  @override
  void didUpdateWidget(ThinkingSendButton old) {
    super.didUpdateWidget(old);
    if (old.thinking == widget.thinking) return;
    final to = widget.thinking ? 1.0 : 0.0;
    if (_still) {
      _morph.value = to;
      _loop.stop();
      return;
    }
    if (widget.thinking) {
      _loop.repeat();
    } else {
      _ripple.forward(from: 0);
    }
    _morph.animateWith(SpringSimulation(AppMotion.spring, _morph.value, to, _morph.velocity)).whenComplete(() {
      // A spring settles within a hair of its end; land exactly on it, so
      // the arrow comes back whole. Not if a newer change took over.
      if (!mounted || widget.thinking != (to == 1)) return;
      _morph.value = to;
      if (!widget.thinking) _loop.stop();
    });
  }

  @override
  void dispose() {
    _morph.dispose();
    _loop.dispose();
    _ripple.dispose();
    super.dispose();
  }

  void _press(bool down) {
    if (widget.thinking || widget.onSend == null) return;
    setState(() => _pressed = down);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final can = widget.onSend != null;
    return Tooltip(
      message: 'Send',
      excludeFromSemantics: true,
      // The thinking bubble already says the coach is at work; the button
      // stays Send, unavailable until the reply.
      child: Semantics(
        button: true,
        enabled: can && !widget.thinking,
        label: 'Send',
        value: widget.thinking ? 'waiting for the coach' : null,
        child: GestureDetector(
          onTap: widget.thinking ? null : widget.onSend,
          onTapDown: (_) => _press(true),
          onTapUp: (_) => _press(false),
          onTapCancel: () => _press(false),
          child: AnimatedScale(
            scale: _pressed ? 0.9 : 1,
            duration: AppMotion.press,
            curve: Curves.easeOutBack,
            child: SizedBox.square(
              dimension: widget.size,
              child: AnimatedBuilder(
                animation: Listenable.merge([_morph, _loop, _ripple]),
                builder: (context, _) {
                  final m = _morph.value;
                  return CustomPaint(
                    painter: _SpherePainter(t: _loop.value, morph: m, ripple: _ripple.value, button: can ? c.primary : c.well, light: c.sphere),
                    child: Center(
                      child: Opacity(
                        opacity: (1 - m * 1.6).clamp(0.0, 1.0),
                        child: Transform.rotate(
                          angle: m * -math.pi * 0.6,
                          child: Transform.scale(
                            scale: (1 - m).clamp(0.0, 1.2),
                            child: Icon(Icons.arrow_upward_rounded, color: can ? c.onPrimary : c.muted),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A point on the unit sphere, turned and tilted, z towards the viewer.
typedef _P = ({double x, double y, double z});

/// One ring orbiting the sphere, its size and speed against the sphere's.
typedef _Ring = ({double radius, double tilt, double spin, double speed, double width, Color colour});

class _SpherePainter extends CustomPainter {
  _SpherePainter({required this.t, required this.morph, required this.ripple, required this.button, required this.light});

  /// Where in its loop the sphere is, 0 to 1.
  final double t;

  /// 0 the arrow's button, 1 the sphere (past 1 while the spring overshoots).
  final double morph;

  /// The collapse ripple, 0 to 1; 1 once it has faded.
  final double ripple;
  final Color button;
  final SphereColours light;

  /// Points spread evenly over a sphere (a Fibonacci lattice).
  static final List<_P> _lattice = () {
    const n = 420;
    final golden = math.pi * (3 - math.sqrt(5));
    return [
      for (var i = 0; i < n; i++)
        () {
          final y = 1 - (i + 0.5) * 2 / n;
          final ring = math.sqrt(1 - y * y);
          return (x: math.cos(golden * i) * ring, y: y, z: math.sin(golden * i) * ring);
        }(),
    ];
  }();

  /// Each grain's own depth inside the glass, so the points read as dust
  /// rather than a pattern.
  static final List<double> _depth = [for (var i = 0; i < _lattice.length; i++) ((math.sin(i * 12.9898) * 43758.5453) % 1).abs()];

  static _P _turn(_P p, double yaw, double pitch) {
    final x1 = p.x * math.cos(yaw) + p.z * math.sin(yaw);
    final z1 = -p.x * math.sin(yaw) + p.z * math.cos(yaw);
    final y2 = p.y * math.cos(pitch) - z1 * math.sin(pitch);
    final z2 = p.y * math.sin(pitch) + z1 * math.cos(pitch);
    return (x: x1, y: y2, z: z2);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final centre = size.center(Offset.zero);
    final full = size.width / 2;
    final a = t * 2 * math.pi;
    final stroke = Paint()..style = PaintingStyle.stroke;
    final fill = Paint();

    // The ripple left as the sphere folds back into the button.
    if (ripple < 1) {
      for (final (lag, width) in [(0.0, 2.5), (0.18, 1.2)]) {
        final k = ((ripple - lag) / (1 - lag)).clamp(0.0, 1.0);
        if (k <= 0 || k >= 1) continue;
        canvas.drawCircle(centre, full * (0.6 + Curves.easeOut.transform(k) * 0.9), stroke
          ..strokeWidth = width * (1 - k)
          ..color = light.glow.withValues(alpha: 0.85 * (1 - k)));
      }
    }

    // The button itself, folding away as the sphere grows.
    final shown = morph.clamp(0.0, 1.0);
    if (shown < 1) canvas.drawCircle(centre, full * (1 - shown * 0.3), fill..color = button.withValues(alpha: 1 - shown));
    if (morph <= 0.01) return;

    final breath = 1 + 0.035 * math.sin(a * 4);
    final r = full * 0.7 * morph.clamp(0.0, 1.3) * breath;
    if (r <= 0) return;
    final orb = Rect.fromCircle(center: centre, radius: r);

    // A halo, brightening with each breath.
    canvas.drawCircle(centre, r * 1.25, Paint()
      ..color = light.glow.withValues(alpha: shown * (0.22 + 0.12 * math.sin(a * 4)))
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.45));

    // Three rings orbit outside the globe, each on its own tilt: their far
    // halves are drawn first so the globe hides them, their near halves last.
    final rings = <_Ring>[
      (radius: 1.32, tilt: 1.15, spin: 0.0, speed: 1.0, width: 0.035, colour: light.glow),
      (radius: 1.18, tilt: -0.85, spin: 1.3, speed: -1.4, width: 0.025, colour: light.blue),
      (radius: 1.45, tilt: 0.35, spin: 2.4, speed: 0.7, width: 0.015, colour: light.core),
    ];
    _P onRing(_Ring g, double u) => _turn((x: math.cos(u), y: 0, z: math.sin(u)), g.spin + a * 0.5 * g.speed.sign, g.tilt);
    void ringHalf(bool front) {
      for (final g in rings) {
        const steps = 96;
        final path = Path();
        var open = false;
        for (var i = 0; i <= steps; i++) {
          final p = onRing(g, i / steps * 2 * math.pi);
          final o = centre + Offset(p.x, p.y) * r * g.radius;
          if ((p.z >= 0) == front) {
            open ? path.lineTo(o.dx, o.dy) : path.moveTo(o.dx, o.dy);
            open = true;
          } else {
            open = false;
          }
        }
        canvas.drawPath(path, Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * g.width * (front ? 1.4 : 0.8)
          ..color = g.colour.withValues(alpha: shown * (front ? 0.55 : 0.14))
          ..maskFilter = front ? MaskFilter.blur(BlurStyle.normal, r * 0.015) : null);
        // A comet running along the ring, its tail fading behind it.
        final head = a * g.speed * 2;
        final tail = Color.lerp(g.colour, light.core, 0.6)!;
        for (var k = 0; k < 44; k++) {
          final p = onRing(g, head - k * 0.03);
          if ((p.z >= 0) != front) continue;
          final fade = 1 - k / 44;
          canvas.drawCircle(centre + Offset(p.x, p.y) * r * g.radius, r * (0.012 + 0.05 * fade * fade), Paint()
            ..color = tail.withValues(alpha: shown * fade * (front ? 1 : 0.3))
            ..maskFilter = k == 0 ? MaskFilter.blur(BlurStyle.normal, r * 0.06) : null);
        }
      }
    }

    ringHalf(false);

    canvas.save();
    canvas.clipPath(Path()..addOval(orb));
    canvas.drawRect(orb, Paint()..shader = RadialGradient(colors: [light.night, light.abyss], stops: const [0.1, 1]).createShader(orb));
    // Plasma deep inside: soft lights drifting at their own speeds.
    for (final (colour, speed, phase, reach, width) in [(light.blue, 1.0, 0.0, 0.35, 0.55), (light.sea, -2.0, 2.1, 0.38, 0.45), (light.glow, 3.0, 4.2, 0.25, 0.3)]) {
      final at = centre + Offset(math.cos(a * speed + phase), math.sin(a * speed + phase) * 0.8) * r * reach;
      canvas.drawCircle(at, r * width, Paint()
        ..color = colour.withValues(alpha: 0.5 * shown)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.32));
    }
    // A fine dust of light on a turning shell, each grain twinkling on its
    // own beat; nearer grains larger and brighter.
    final yaw = a, pitch = 0.45 + 0.15 * math.sin(a);
    for (final (i, p) in _lattice.indexed) {
      final q = _turn(p, yaw, pitch);
      final near = (q.z + 1) / 2;
      final twinkle = 0.55 + 0.45 * math.sin(a * 6 + i * 2.39);
      fill.color = Color.lerp(light.blue, light.core, near)!.withValues(alpha: shown * twinkle * (0.08 + 0.92 * near * near));
      canvas.drawCircle(centre + Offset(q.x, q.y) * r * (0.5 + 0.4 * _depth[i]), r * (0.005 + 0.015 * near), fill);
    }
    // The core, pulsing at the heart.
    canvas.drawCircle(centre, r * (0.2 + 0.05 * math.sin(a * 4)), Paint()
      ..color = light.core.withValues(alpha: shown * (0.7 + 0.25 * math.sin(a * 4)))
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.16));
    canvas.drawCircle(centre, r * 0.07, fill..color = light.core.withValues(alpha: shown));
    // A rim of light on the inside of the glass, and a glint at the top
    // left, where the app's light falls.
    canvas.drawCircle(centre, r, Paint()
      ..shader = RadialGradient(colors: [light.glow.withValues(alpha: 0), light.glow.withValues(alpha: 0), light.glow.withValues(alpha: 0.7 * shown)], stops: const [0, 0.78, 1])
          .createShader(orb));
    canvas.drawCircle(centre + Offset(-r * 0.42, -r * 0.48), r * 0.15, Paint()
      ..color = light.core.withValues(alpha: 0.32 * shown)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.09));
    canvas.restore();

    ringHalf(true);
  }

  @override
  bool shouldRepaint(_SpherePainter old) => old.t != t || old.morph != morph || old.ripple != ripple || old.button != button;
}
