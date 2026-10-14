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

/// Lays [children] out top to bottom, each rising and fading in a moment after
/// the one above it. With the system's reduce-motion setting on, they appear
/// in place.
class RiseIn extends ConsumerWidget {
  const RiseIn({super.key, required this.children, this.spacing = 0});

  final List<Widget> children;
  final double spacing;

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
