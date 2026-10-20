import 'package:bajet/features/lock/domain/unlock_flight.dart';
import 'package:bajet/features/opening/domain/opening_timeline.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const fan = LockTarget(Offset(180, 300));
  const stack = StackTarget(Rect.fromLTWH(22, 96, 305, 160), Rect.fromLTWH(19, 105, 316, 166), Rect.fromLTWH(16, 114, 328, 173));
  const end = UnlockTimes.end;

  test("the cards start exactly where the lock screen's fan draws them", () {
    final plan = UnlockPlan(fan, stack);
    for (var i = 0; i < 3; i++) {
      final a = OpeningPlan.angles[i];
      final p = plan.card(i, 0);
      expect((p.centre, p.width, p.turn), (fan.centre + OpeningPlan.fanOffset(a) * fan.scale, OpeningPlan.cardWidth * fan.scale, a));
      expect((plan.titanium(i, 0), plan.real(i, 0)), (1, 0));
    }
    expect((plan.words(0), plan.backdrop(0)), (0, 1));
  });

  test('the front card leaves first, and all three land in the stack as its real cards', () {
    final plan = UnlockPlan(fan, stack);
    final first = UnlockTimes.fly + 1;
    expect(plan.card(2, first).centre, isNot(plan.card(2, 0).centre));
    expect(plan.card(0, first).centre, plan.card(0, 0).centre);
    for (var i = 0; i < 3; i++) {
      final p = plan.card(i, end);
      expect((p.centre, p.width, p.turn), (stack[i].center, stack[i].width, 0));
      expect((plan.titanium(i, end), plan.real(i, end)), (0, 1));
    }
    expect(plan.lands, isTrue);
  });

  test('the words step aside first, and the lock lifts before the cards land', () {
    final plan = UnlockPlan(fan, stack);
    expect(plan.words(UnlockTimes.words), 1);
    expect(plan.backdrop(UnlockTimes.lift - 1), 1);
    expect(plan.backdrop(end - 100), 0);
  });

  test('with no stack to land in, the fan fades where it is', () {
    final plan = UnlockPlan(fan, null);
    expect(plan.lands, isFalse);
    for (var i = 0; i < 3; i++) {
      expect(plan.card(i, end).centre, plan.card(i, 0).centre);
      expect(plan.titanium(i, end), 0);
    }
  });
}
