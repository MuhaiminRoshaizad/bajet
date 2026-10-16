import 'package:bajet/features/opening/domain/opening_timeline.dart';
import 'package:flutter/animation.dart';
import 'package:flutter_test/flutter_test.dart';

// ignore: camel_case_types
typedef t = OpeningTimes;

void main() {
  const size = Size(360, 780);
  const stack = StackTarget(Rect.fromLTWH(22, 96, 305, 160), Rect.fromLTWH(19, 105, 316, 166), Rect.fromLTWH(16, 114, 328, 173));
  final plan = OpeningPlan(size, stack);


  group('tracks behave like the mock-up\'s Web Animations', () {
    final track = Track<double>(100, 100, const [Frame(0, 0), Frame(.5, 10), Frame(1, 4)], lerpNum);

    test('nothing before the start unless it fills backwards, the last frame after the end', () {
      expect(track.at(50), isNull);
      expect(Track<double>(100, 100, const [Frame(0, 7), Frame(1, 9)], lerpNum, fillBefore: true).at(50), 7);
      expect(track.at(150), 10);
      expect(track.at(400), 4);
    });

    test('a later track wins once it has started', () {
      final later = Track<double>(160, 100, const [Frame(0, 50), Frame(1, 60)], lerpNum);
      expect(resolve([track, later], 150, -1.0), 10);
      expect(resolve([track, later], 160, -1.0), 50);
      expect(resolve(<Track<double>>[], 0, -1.0), -1);
    });

    test('the easing over the whole track bends time before the keyframes', () {
      final eased = Track<double>(0, 100, const [Frame(0, 0), Frame(1, 1)], lerpNum, curve: OpeningCurves.soft);
      expect(eased.at(50), closeTo(OpeningCurves.soft.transform(.5), 1e-9));
    });
  });

  test("Android's part, the deal and the word, ends within a second, with everything settled", () {
    expect(t.dealEnd, lessThanOrEqualTo(1000));
    for (var i = 0; i < 3; i++) {
      expect(plan.card(i, t.dealEnd).turn, OpeningPlan.angles[i]);
    }
    for (var i = 0; i < 5; i++) {
      expect(plan.letter(i, t.dealEnd), (drop: 0.0, blur: 0.0, opacity: 1.0));
    }
    expect(plan.lineAt(t.dealEnd), 1);
  });

  test('the front card arrives alone, small and tilted, and settles upright in the middle', () {
    expect(plan.card(2, 0).opacity, 0);
    expect(plan.card(2, 0).turn, -10);
    expect(plan.card(2, 0).width, closeTo(OpeningPlan.cardWidth * .55, 1e-9));
    final settled = plan.card(2, t.pop + 260 * t.pace);
    expect((settled.centre, settled.width, settled.turn, settled.opacity), (plan.fanAt(0), OpeningPlan.cardWidth, 0, 1));
    expect(plan.card(1, t.mid - 1).opacity, 0, reason: 'the second card is still hidden');
  });

  test('the second and third cards slide out to the lower left of the one before', () {
    expect(plan.card(1, t.mid + 279.9).centre.dx, lessThan(plan.fanAt(0).dx));
    expect(plan.card(0, t.back + 200).centre.dy, greaterThan(plan.card(1, t.back + 200).centre.dy));
  });

  test('the fan swings past its angles at 40% and settles on them', () {
    // Each keyframe is reached exactly, whatever the easing between them.
    expect(plan.card(2, t.fan + 380 * t.pace * .4).turn, closeTo(20 * 1.42, 1e-4));
    expect(plan.card(2, t.fan + 380 * t.pace * .4).width, closeTo(OpeningPlan.cardWidth * 1.04, 1e-4));
    expect(plan.card(0, t.fan + 380 * t.pace * .6).turn, closeTo(-20 * .84, 1e-4));
    for (var i = 0; i < 3; i++) {
      final p = plan.card(i, t.dealEnd);
      expect((p.centre, p.turn), (plan.fanAt(OpeningPlan.angles[i]), OpeningPlan.angles[i]));
    }
  });

  test('the fan is centred, with its outermost corner inside the 66 dp circle', () {
    final mid = (plan.fanAt(-20) + plan.fanAt(20)) / 2;
    expect(mid.dx, plan.fanCentre.dx);
  });

  test('each letter rises past its line, dips, and sits on it; then all lift away', () {
    expect(plan.letter(0, 0), (drop: 1.15, blur: 4.0, opacity: 0.0));
    final settled = plan.letter(4, t.word + 4 * 40 + 280);
    expect((settled.drop, settled.opacity), (0, 1));
    expect(plan.letter(0, t.out + 220).opacity, 0);
    expect(plan.lineAt(t.line - 1), 0);
    expect(plan.lineAt(t.line + 260), 1);
    expect(plan.lineAt(t.out + 240), 0);
  });

  test('the cards land on Today: back on the deepest account, front on the total', () {
    for (var i = 0; i < 3; i++) {
      final p = plan.card(i, t.end);
      expect((p.centre, p.width, p.turn), (stack[i].center, stack[i].width, 0));
      expect((plan.real(i, t.end), plan.titanium(i, t.end)), (1, 0));
    }
    expect(plan.backdropAt(t.end), 0);
    final widths = [for (var ms = t.fly + 300; ms < t.fly + 600; ms += 5) plan.card(2, ms).width];
    expect(widths.reduce((a, b) => a > b ? a : b), greaterThan(stack.total.width), reason: 'a small settle before it lands');
  });

  test('with the lock on they land small on the lock screen, still titanium', () {
    const centre = Offset(180, 260);
    final locked = OpeningPlan(size, const LockTarget(centre));
    for (var i = 0; i < 3; i++) {
      final p = locked.card(i, t.end);
      final a = OpeningPlan.angles[i];
      expect(p.centre.dx, closeTo(centre.dx + OpeningPlan.fanOffset(a).dx * .55, 1e-9));
      expect(p.width, closeTo(OpeningPlan.cardWidth * .55, 1e-9));
      expect(locked.titanium(i, t.end), 1);
    }
  });

  test('with nowhere to land, as on first-run setup, the cards fade away', () {
    final none = OpeningPlan(size, const NoTarget());
    expect(none.titanium(2, t.end), 0);
  });
}
