import '../../opening/domain/opening_timeline.dart';

/// The lock screen leaving once it is unlocked (docs/design-system.md, App
/// lock): its words step aside, its fan flies into Today's stack the way
/// the opening's cards do, and its background lifts. Milliseconds from the
/// unlock.
abstract final class UnlockTimes {
  static const words = 180.0;
  static const fly = 80.0;
  static const lift = fly + 60;
  static const rise = fly + 350;
  static const end = fly + 2 * 50 + StackFlight.duration + 100;
}

/// Every track of the unlock, from the lock screen's fan at [from] to
/// Today's stack at [to]; with no stack to land in, the fan fades where it
/// is.
class UnlockPlan {
  UnlockPlan(this.from, StackTarget? to) {
    for (var i = 0; i < 3; i++) {
      final start = UnlockTimes.fly + (2 - i) * 50;
      if (to == null) {
        _titanium.add([fadeInPlace(start)]);
        continue;
      }
      final flight = StackFlight(_rest(i), to[i], start);
      _cards.add([flight.pose]);
      _real.add([flight.real]);
      _titanium.add([flight.titanium]);
    }
  }

  final LockTarget from;
  final _cards = <List<Track<CardPose>>>[];
  final _real = <List<Track<double>>>[];
  final _titanium = <List<Track<double>>>[];

  static final _words = Track<double>(0, UnlockTimes.words, const [Frame(0, 0), Frame(1, 1)], lerpNum, curve: OpeningCurves.easeIn);
  static final _backdrop = Track<double>(UnlockTimes.lift, 460, const [Frame(0, 1), Frame(1, 0)], lerpNum, curve: OpeningCurves.easeOut);

  /// Card [i] as the lock screen's fan draws it.
  CardPose _rest(int i) {
    final a = OpeningPlan.angles[i];
    return CardPose(from.centre + OpeningPlan.fanOffset(a) * from.scale, OpeningPlan.cardWidth * from.scale, a);
  }

  /// Whether the cards land in Today's stack, and so show its faces.
  bool get lands => _cards.isNotEmpty;

  CardPose card(int i, double ms) => _cards.isEmpty ? _rest(i) : resolve(_cards[i], ms, _rest(i));
  double real(int i, double ms) => _real.isEmpty ? 0 : resolve(_real[i], ms, 0);
  double titanium(int i, double ms) => resolve(_titanium[i], ms, 1);

  /// How far the words have stepped aside, 0 to 1.
  double words(double ms) => resolve([_words], ms, 0);

  /// The lock screen's background, 1 while it covers the app.
  double backdrop(double ms) => resolve([_backdrop], ms, 1);
}
