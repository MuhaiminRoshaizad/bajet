import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/rise_in.dart';
import '../domain/opening_timeline.dart';

/// What main overrides to play the opening: the screens underneath hold
/// their entrance until the cards have landed.
final openingEntranceHold = Duration(milliseconds: OpeningTimes.rise.round());

/// Whether this launch plays the opening. Overridden in main, so tests and
/// anything else that builds the app start straight on their screen.
final playOpeningProvider = Provider<bool>((ref) => false);

/// Where the opening's cards land: Today's stack and the lock screen's fan.
final openingStackKey = GlobalKey(debugLabel: 'opening-stack');
final openingLockMarkKey = GlobalKey(debugLabel: 'opening-lock-mark');

/// True while the opening plays over the app.
class OpeningController extends Notifier<bool> {
  @override
  bool build() => ref.watch(playOpeningProvider);

  /// At the end, or straight away when the owner taps to skip; a skip lets
  /// the screen underneath make its entrance now.
  void finish({bool skipped = false}) {
    if (!state) return;
    state = false;
    if (skipped) {
      ref.read(entranceHoldProvider.notifier).release();
      ref.read(screenEntryProvider.notifier).arrive();
    }
  }
}

final openingProvider = NotifierProvider<OpeningController, bool>(OpeningController.new);
