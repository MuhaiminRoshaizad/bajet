import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/rise_in.dart';
import '../../accounts/presentation/account_providers.dart';
import '../../opening/domain/opening_timeline.dart';
import '../../opening/presentation/flying_card.dart';
import '../../opening/presentation/opening_providers.dart';
import '../domain/unlock_flight.dart';
import 'lock_providers.dart';

/// The lock screen's background and [child], its words, and once it is
/// unlocked their exit (UnlockPlan): the words step aside, the fan's cards
/// fly into Today's stack and the background lifts. A tap lands at once;
/// with the system's remove animations setting on, nothing moves.
class UnlockExit extends ConsumerStatefulWidget {
  const UnlockExit({super.key, required this.landOnToday, required this.child});

  final Future<StackTarget?> Function() landOnToday;
  final Widget child;

  @override
  ConsumerState<UnlockExit> createState() => _UnlockExitState();
}

class _UnlockExitState extends ConsumerState<UnlockExit> with SingleTickerProviderStateMixin {
  late final AnimationController _clock = AnimationController(vsync: this, duration: Duration(milliseconds: UnlockTimes.end.round()))
    ..addListener(() {
      if (_clock.value >= UnlockTimes.rise / UnlockTimes.end) ref.read(entranceHoldProvider.notifier).release();
    })
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed) _land();
    });
  UnlockPlan? _plan;

  @override
  void initState() {
    super.initState();
    ref.listenManual(unlockFlightProvider, (_, flying) {
      if (flying) _start();
    });
  }

  Future<void> _start() async {
    final mark = openingLockMarkKey.currentContext?.findRenderObject() as RenderBox?;
    if (MediaQuery.disableAnimationsOf(context) || mark == null || !mark.hasSize) {
      await widget.landOnToday();
      return _land();
    }
    final from = LockTarget(mark.localToGlobal(mark.size.center(Offset.zero)));
    // The fan's cards take over from the fan at once, resting where it was
    // drawn, while Today lays out underneath.
    setState(() => _plan = UnlockPlan(from, null));
    final to = await widget.landOnToday();
    if (!mounted) return;
    setState(() => _plan = UnlockPlan(from, to));
    _clock.forward();
  }

  void _land() {
    _clock.stop();
    ref.read(unlockFlightProvider.notifier).land();
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final plan = _plan;
    final accounts = ref.watch(accountsProvider).value ?? const [];
    // Laid out at Today's width, as the opening's cards are.
    final base = MediaQuery.sizeOf(context).width - 32;
    // Above the navigator there is no Material for text to take its style
    // from, the lock's words and the flying cards' faces alike.
    return Material(
      type: MaterialType.transparency,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: plan == null ? null : (_) => _land(),
        child: AnimatedBuilder(
          animation: _clock,
          builder: (context, child) {
            final ms = _clock.value * UnlockTimes.end;
            final out = plan?.words(ms) ?? 0;
            // The words stay in the same place in the tree throughout, so the
            // lock screen keeps its state as it leaves.
            return Stack(children: [
              Positioned.fill(child: ColoredBox(color: c.background.withValues(alpha: plan?.backdrop(ms) ?? 1))),
              Positioned.fill(
                child: Opacity(opacity: 1 - out, child: Transform.translate(offset: Offset(0, 12 * out), child: child)),
              ),
              if (plan != null)
                for (var i = 0; i < 3; i++)
                  FlyingCard(
                    pose: plan.card(i, ms),
                    base: base,
                    depth: i,
                    titanium: plan.titanium(i, ms),
                    face: plan.lands ? stackFace(i, accounts) : null,
                    shown: plan.real(i, ms),
                  ),
            ]);
          },
          // Unlocked, so its buttons no longer answer.
          child: IgnorePointer(ignoring: plan != null, child: widget.child),
        ),
      ),
    );
  }
}
