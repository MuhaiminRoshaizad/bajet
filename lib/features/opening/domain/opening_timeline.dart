import 'dart:math' as math;

import 'package:flutter/animation.dart';

/// The opening, from the approved motion mock-up: one titanium card, then
/// two, then three spring into the fan, "bajet" rises under it, and the
/// cards arc into Today's stack or onto the lock screen.
///
/// Up to [dealEnd] it is Android's splash animation, which Android plays
/// the moment the icon is tapped and asks to keep within a second; so the
/// mock-up's deal runs at [pace]. `res/drawable-v31/splash_deal.xml` is
/// generated from this timeline (test/features/opening/splash_deal_test.dart).
/// From [dealEnd] on, bajet plays the hand-over at the mock-up's own speed.
///
/// It is written the way the mock-up's Web Animations were: each track has
/// a start, a length, an easing over the whole track and keyframes, and
/// where tracks overlap the one added later wins. Times are milliseconds
/// from the tap.
abstract final class OpeningTimes {
  static const pace = .62;
  static const pop = 60 * pace;
  static const mid = 280 * pace;
  static const back = 420 * pace;
  static const fan = 640 * pace;
  static const word = 560.0;
  static const line = 720.0;
  static const dealEnd = 1000.0;
  static const out = dealEnd;
  static const fly = out + 50;
  static const rise = fly + 350;
  static const end = fly + 100 + 600 + 50;
}

/// The mock-up's three curves, as CSS cubic-béziers.
abstract final class OpeningCurves {
  static const soft = Cubic(.33, 0, .3, 1);
  static const emphasized = Cubic(.2, 0, 0, 1);
  static const easeInOut = Cubic(.42, 0, .58, 1);
  static const easeIn = Cubic(.42, 0, 1, 1);
  static const easeOut = Cubic(0, 0, .58, 1);
}

/// One keyframe: where it sits on the track, its value, and the easing to
/// the next keyframe.
class Frame<T> {
  const Frame(this.offset, this.value, [this.curve = Curves.linear]);

  final double offset;
  final T value;
  final Curve curve;
}

/// A value animated over time, like one `element.animate()` call.
class Track<T> {
  const Track(this.start, this.duration, this.frames, this.lerp, {this.curve = Curves.linear, this.fillBefore = false});

  final double start;
  final double duration;
  final List<Frame<T>> frames;
  final T Function(T a, T b, double t) lerp;
  final Curve curve;

  /// Whether the first frame holds before the track starts. After the end
  /// the last frame always holds.
  final bool fillBefore;

  /// The value at [ms], or null while the track has not started and does
  /// not fill backwards.
  T? at(double ms) {
    if (ms < start && !fillBefore) return null;
    final p = curve.transform(((ms - start) / duration).clamp(0.0, 1.0));
    var i = 0;
    while (i < frames.length - 2 && p > frames[i + 1].offset) {
      i++;
    }
    final a = frames[i], b = frames[i + 1];
    final span = b.offset - a.offset;
    final local = span <= 0 ? 1.0 : ((p - a.offset) / span).clamp(0.0, 1.0);
    return lerp(a.value, b.value, a.curve.transform(local));
  }
}

/// Whatever the latest started track says, or [base] when none has.
T resolve<T>(List<Track<T>> tracks, double ms, T base) {
  for (final t in tracks.reversed) {
    final v = t.at(ms);
    if (v != null) return v;
  }
  return base;
}

double lerpNum(double a, double b, double t) => a + (b - a) * t;

/// Where a card is: its centre, its width (height follows from the card's
/// shape), how far it is turned in degrees, and how opaque.
class CardPose {
  const CardPose(this.centre, this.width, this.turn, [this.opacity = 1]);

  final Offset centre;
  final double width;
  final double turn;
  final double opacity;

  CardPose withOpacity(double o) => CardPose(centre, width, turn, o);

  static CardPose lerp(CardPose a, CardPose b, double t) => CardPose(
        Offset.lerp(a.centre, b.centre, t)!,
        lerpNum(a.width, b.width, t),
        lerpNum(a.turn, b.turn, t),
        lerpNum(a.opacity, b.opacity, t),
      );

  @override
  bool operator ==(Object other) => other is CardPose && other.centre == centre && other.width == width && other.turn == turn && other.opacity == opacity;

  @override
  int get hashCode => Object.hash(centre, width, turn, opacity);

  @override
  String toString() => 'CardPose(${centre.dx.toStringAsFixed(1)}, ${centre.dy.toStringAsFixed(1)}, w ${width.toStringAsFixed(1)}, ${turn.toStringAsFixed(1)}°, ${opacity.toStringAsFixed(2)})';
}

/// One letter of the wordmark: how far below its line it sits, as a share
/// of its height, its blur, and its opacity.
typedef Letter = ({double drop, double blur, double opacity});

Letter _lerpLetter(Letter a, Letter b, double t) =>
    (drop: lerpNum(a.drop, b.drop, t), blur: lerpNum(a.blur, b.blur, t), opacity: lerpNum(a.opacity, b.opacity, t));

/// Where the opening ends up: Today's stack, the lock screen's small fan,
/// or nowhere (first-run setup), in which case the cards simply fade.
sealed class OpeningTarget {
  const OpeningTarget();
}

/// The three places the cards land, back to front: the deepest peeking
/// account, the nearer one, and the total.
class StackTarget extends OpeningTarget {
  const StackTarget(this.back, this.mid, this.total);

  final Rect back, mid, total;

  Rect operator [](int i) => [back, mid, total][i];
}

/// The centre of the lock screen's fan, drawn at [scale] of the opening's.
class LockTarget extends OpeningTarget {
  const LockTarget(this.centre, {this.scale = .55});

  final Offset centre;
  final double scale;
}

class NoTarget extends OpeningTarget {
  const NoTarget();
}

/// Every track of the opening for a screen of [size].
class OpeningPlan {
  OpeningPlan(this.size, this.target) {
    _build();
  }

  final Size size;
  final OpeningTarget target;

  /// Android's splash keeps only a circle 192 dp across in view, so the
  /// mock-up's opening is drawn at this share of its size: every card, even
  /// mid-bounce, the word and its line stay inside that circle
  /// (test/features/opening/splash_deal_test.dart checks).
  static const zoom = .82;

  /// The icon's 108-unit canvas is drawn at this many logical pixels a unit.
  static const k = 2.2 * zoom;
  static const lineWidth = 132 * zoom;
  static const cardWidth = 40 * k;
  static const angles = [-20.0, 0.0, 20.0];
  static const _midOffset = Offset(-16 * zoom, 11 * zoom), _backOffset = Offset(-30 * zoom, 21 * zoom);

  /// The fan sits a little above the middle, leaving room for the word.
  late final Offset fanCentre = Offset(size.width / 2, size.height / 2 - 20 * zoom);
  late final double wordTop = fanCentre.dy + 64 * zoom;
  late final double lineTop = wordTop + 44 * zoom;

  /// A card's centre in the fan at angle [a]: as in the launcher icon, the
  /// cards turn about a point below them.
  Offset fanAt(double a) => fanCentre + fanOffset(a);

  /// The same, measured from the fan's centre, for a fan drawn anywhere.
  static Offset fanOffset(double a) {
    const c = Offset(0, -1.85 * k), p = Offset(0, 28.65 * k);
    final r = a * math.pi / 180, d = c - p;
    return Offset(p.dx + d.dx * math.cos(r) - d.dy * math.sin(r), p.dy + d.dx * math.sin(r) + d.dy * math.cos(r));
  }

  CardPose _at(double a, [Offset by = Offset.zero, double scale = 1, double? turn]) => CardPose(fanAt(a) + by, cardWidth * scale, turn ?? a);

  /// Per card, back to front.
  final cards = List.generate(3, (_) => <Track<CardPose>>[]);
  final realFaces = List.generate(3, (_) => <Track<double>>[]);
  final titaniumFaces = List.generate(3, (_) => <Track<double>>[]);
  final letters = List.generate(5, (_) => <Track<Letter>>[]);
  final letterLift = List.generate(5, (_) => <Track<double>>[]);
  final line = <Track<double>>[];
  final backdrop = <Track<double>>[];

  void _build() {
    Track<CardPose> pose(double start, double duration, List<Frame<CardPose>> frames, {Curve curve = Curves.linear, bool fillBefore = false}) =>
        Track(start, duration, frames, CardPose.lerp, curve: curve, fillBefore: fillBefore);
    Track<double> number(double start, double duration, List<Frame<double>> frames, {Curve curve = Curves.linear, bool fillBefore = false}) =>
        Track(start, duration, frames, lerpNum, curve: curve, fillBefore: fillBefore);

    // 1. The front card arrives alone, with a little tilt. Steps 1 to 4
    // are Android's splash animation.
    cards[2].add(pose(OpeningTimes.pop, 260 * OpeningTimes.pace, [
      Frame(0, _at(0, const Offset(0, 16 * zoom), .55, -10).withOpacity(0)),
      Frame(.55, _at(0, const Offset(0, -3 * zoom), 1.07, 3)),
      Frame(.8, _at(0, const Offset(0, 1 * zoom), .98, -1)),
      Frame(1, _at(0)),
    ], curve: OpeningCurves.soft, fillBefore: true));

    // 2. A second card slides out from behind it, then a third.
    Track<CardPose> slide(Offset from, Offset to, double start) => pose(start, 280 * OpeningTimes.pace, [
          Frame(0, _at(0, from).withOpacity(0)),
          Frame(.12, _at(0, from)),
          Frame(.6, _at(0, to * 1.3, 1, -4)),
          Frame(.82, _at(0, to * .9, 1, 1)),
          Frame(1, _at(0, to)),
        ], curve: OpeningCurves.soft, fillBefore: true);
    cards[1].add(slide(Offset.zero, _midOffset, OpeningTimes.mid));
    cards[0].add(slide(_midOffset, _backOffset, OpeningTimes.back));

    // 3. All three spring into the fan: past it, back, and two smaller bounces.
    const swing = [(0.0, 0.0), (.4, 1.42), (.6, .84), (.76, 1.1), (.9, .97), (1.0, 1.0)];
    for (final (i, from) in [(0, _backOffset), (1, _midOffset), (2, Offset.zero)]) {
      final a = angles[i];
      cards[i].add(pose(OpeningTimes.fan, 380 * OpeningTimes.pace, [
        for (final (o, m) in swing) Frame(o, _at(a * m, from * (1 - math.min(1, o * 1.6)), o == .4 ? 1.04 : 1), OpeningCurves.soft),
      ]));
    }

    // 4. The word: each letter rises from behind its line with a soft bounce.
    for (var i = 0; i < 5; i++) {
      letters[i].add(Track(OpeningTimes.word + i * 40, 280, const [
        Frame(0, (drop: 1.15, blur: 4.0, opacity: 0.0)),
        Frame(.62, (drop: -.12, blur: 0.0, opacity: 1.0)),
        Frame(.82, (drop: .04, blur: 0.0, opacity: 1.0)),
        Frame(1, (drop: 0.0, blur: 0.0, opacity: 1.0)),
      ], _lerpLetter, curve: OpeningCurves.soft, fillBefore: true));
      letterLift[i].add(number(OpeningTimes.out + i * 30, 220, const [Frame(0, 0), Frame(1, 1)], curve: OpeningCurves.easeIn));
    }
    // The line draws out from the middle, then closes as the word lifts away.
    line.add(number(OpeningTimes.line, 260, const [Frame(0, 0), Frame(1, 1)], curve: OpeningCurves.emphasized, fillBefore: true));
    line.add(number(OpeningTimes.out, 240, const [Frame(0, 1), Frame(1, 0)], curve: OpeningCurves.easeIn));

    // 5. Off to where they belong; the graphite lifts.
    backdrop.add(number(OpeningTimes.fly + 60, 460, const [Frame(0, 1), Frame(1, 0)], curve: OpeningCurves.easeOut));
    final target = this.target;
    for (var i = 0; i < 3; i++) {
      final a = angles[i], from = _at(a), d = OpeningTimes.fly + (2 - i) * 50;
      switch (target) {
        case StackTarget():
          final r = target[i], p = fanAt(a);
          final m = (r.center - p) * .5 + const Offset(0, -46 * zoom);
          cards[i].add(pose(d, 600, [
            Frame(0, from),
            Frame(.5, CardPose(p + m, cardWidth * ((1 + r.width / cardWidth) / 2 * 1.05), a * .35)),
            Frame(.84, CardPose(r.center + const Offset(0, 4), r.width * 1.012, 0)),
            Frame(1, CardPose(r.center, r.width, 0)),
          ], curve: OpeningCurves.soft));
          realFaces[i].add(number(d + 240, 260, const [Frame(0, 0), Frame(1, 1)], curve: OpeningCurves.easeOut));
          titaniumFaces[i].add(number(d + 300, 260, const [Frame(0, 1), Frame(1, 0)]));
        case LockTarget(:final centre, :final scale):
          final p = fanAt(a), to = centre + (p - fanCentre) * scale - p;
          cards[i].add(pose(d, 560, [
            Frame(0, from),
            Frame(.55, _at(a, to * .55 + const Offset(0, -30 * zoom), .7, a * 1.2)),
            Frame(.85, _at(a, to + const Offset(0, 3 * zoom), scale - .01)),
            Frame(1, _at(a, to, scale)),
          ], curve: OpeningCurves.soft));
        case NoTarget():
          titaniumFaces[i].add(number(d, 300, const [Frame(0, 1), Frame(1, 0)], curve: OpeningCurves.easeIn));
      }
    }
  }

  /// A card's pose at [ms]. Before anything has moved it, it rests where it
  /// will land, as the mock-up's cards rested in Today's stack.
  CardPose card(int i, double ms) => resolve(cards[i], ms, _rest(i));

  CardPose _rest(int i) => switch (target) {
        StackTarget t => CardPose(t[i].center, t[i].width, 0),
        _ => _at(angles[i]),
      };

  double real(int i, double ms) => resolve(realFaces[i], ms, 0);
  double titanium(int i, double ms) => resolve(titaniumFaces[i], ms, 1);
  Letter letter(int i, double ms) {
    final l = resolve(letters[i], ms, (drop: 0.0, blur: 0.0, opacity: 1.0));
    final lift = resolve(letterLift[i], ms, 0.0);
    // The word lifts 14 of the mock-up's 34 px letter height.
    return (drop: l.drop - lift * 14 / 34, blur: l.blur, opacity: l.opacity * (1 - lift));
  }

  double lineAt(double ms) => resolve(line, ms, 0);
  double backdropAt(double ms) => resolve(backdrop, ms, 1);
}
