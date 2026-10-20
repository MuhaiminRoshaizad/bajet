import 'package:flutter/widgets.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_motion.dart';

/// Counts arrivals at a top-level screen. Tabs keep their state, so screens
/// key their entrance on this to replay it each time they are opened.
class ScreenEntry extends Notifier<int> {
  @override
  int build() => 0;

  void arrive() => state++;
}

final screenEntryProvider = NotifierProvider<ScreenEntry, int>(ScreenEntry.new);

/// Whether the first screens of a launch hold their entrance, for
/// something that plays over them first, such as the opening. Overridden in
/// main.
final initialEntranceHoldProvider = Provider<bool>((ref) => false);

/// While true, entrances wait, laid out but unseen; released, they play.
class EntranceHold extends Notifier<bool> {
  @override
  bool build() => ref.watch(initialEntranceHoldProvider);

  void hold() => state = true;

  void release() => state = false;
}

final entranceHoldProvider = NotifierProvider<EntranceHold, bool>(EntranceHold.new);

/// Lays [children] out top to bottom, each rising and fading in a moment after
/// the one above it. With the system's reduce-motion setting on, they appear
/// in place.
class RiseIn extends ConsumerWidget {
  const RiseIn({super.key, required this.children, this.spacing = 0, this.held});

  final List<Widget> children;
  final double spacing;

  /// Whether to wait, for a screen that waits on something other than the
  /// app's [entranceHoldProvider].
  final bool? held;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spaced = [
      for (final (i, child) in children.indexed) ...[
        if (i > 0 && spacing > 0) SizedBox(height: spacing),
        child,
      ],
    ];
    if (MediaQuery.disableAnimationsOf(context)) {
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: spaced);
    }
    // Laid out, so the opening can find where to land, but not yet seen.
    if (held ?? ref.watch(entranceHoldProvider)) {
      return Opacity(opacity: 0, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: spaced));
    }
    return Column(
      key: ValueKey(ref.watch(screenEntryProvider)),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: AnimateList(
        interval: AppMotion.stagger,
        effects: [
          const FadeEffect(duration: AppMotion.enter, curve: AppMotion.ease),
          const MoveEffect(begin: Offset(0, AppMotion.rise), end: Offset.zero, duration: AppMotion.enter, curve: AppMotion.ease),
        ],
        children: spaced,
      ),
    );
  }
}
