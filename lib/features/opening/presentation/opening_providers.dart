import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/rise_in.dart';
import '../data/splash_hand_over.dart';

/// Whether this launch plays the opening. Overridden in main, so tests and
/// anything else that builds the app start straight on their screen.
final playOpeningProvider = Provider<bool>((ref) => false);

final splashHandOverProvider = Provider<SplashHandOver>((ref) => const ChannelSplashHandOver());

/// Where the opening's cards land: Today's stack and the lock screen's fan.
final openingStackKey = GlobalKey(debugLabel: 'opening-stack');
final openingLockMarkKey = GlobalKey(debugLabel: 'opening-lock-mark');

/// True while the opening plays over the app.
class OpeningController extends Notifier<bool> {
  @override
  bool build() => ref.watch(playOpeningProvider);

  /// At the end, or straight away when the user taps to skip. Either way
  /// the screen underneath may make its entrance, if it has not yet.
  void finish() {
    if (!state) return;
    state = false;
    ref.read(entranceHoldProvider.notifier).release();
  }
}

final openingProvider = NotifierProvider<OpeningController, bool>(OpeningController.new);
