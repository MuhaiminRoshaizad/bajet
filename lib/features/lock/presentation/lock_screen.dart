import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/rise_in.dart';
import '../../opening/presentation/opening_providers.dart';
import '../../opening/presentation/titanium_card.dart';
import '../../opening/domain/opening_timeline.dart';
import '../domain/app_lock.dart';
import 'lock_providers.dart';
import 'unlock_exit.dart';

/// Covers the app while it is locked. Sits above the navigator, so the lock
/// needs no route. Unlocking always opens on Today, where the lock's fan
/// flies into the stack.
class LockGate extends ConsumerWidget {
  const LockGate({super.key, required this.landOnToday, required this.child});

  /// Takes the app to Today and says where its stack is once laid out.
  final Future<StackTarget?> Function() landOnToday;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locked = ref.watch(appLockProvider);
    return Stack(
      children: [
        // Hidden from TalkBack and frozen while covered, so nothing behind
        // the lock can be read out or keeps animating.
        ExcludeSemantics(excluding: locked, child: TickerMode(enabled: !locked, child: child)),
        // Kept through the unlock while its fan flies off, as the same
        // screen, so it does not ask again.
        if (locked || ref.watch(unlockFlightProvider)) Positioned.fill(child: LockScreen(landOnToday: landOnToday)),
      ],
    );
  }
}

enum _Status { asking, cancelled, failed, lockedOut, unavailable }

/// Asks for the fingerprint as soon as it shows, or once the opening has
/// landed on it, and again on a tap.
class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key, required this.landOnToday});

  final Future<StackTarget?> Function() landOnToday;

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  var _status = _Status.asking;
  var _busy = false;

  @override
  void initState() {
    super.initState();
    if (!ref.read(openingProvider)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _ask());
      return;
    }
    ref.listenManual(openingProvider, (_, playing) {
      if (!playing) _ask();
    });
  }

  Future<void> _ask() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _status = _Status.asking;
    });
    final outcome = await ref.read(deviceAuthProvider).authenticate(title: 'Unlock bajet', reason: 'Your money stays hidden until you do.');
    if (!mounted) return;
    if (outcome == AuthOutcome.passed) return ref.read(appLockProvider.notifier).unlock();
    setState(() {
      _busy = false;
      _status = switch (outcome) {
        AuthOutcome.cancelled || AuthOutcome.passed => _Status.cancelled,
        AuthOutcome.failed => _Status.failed,
        AuthOutcome.lockedOut => _Status.lockedOut,
        AuthOutcome.unavailable => _Status.unavailable,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    final (title, body) = switch (_status) {
      _Status.asking || _Status.cancelled => ('bajet is locked', 'Use your fingerprint to open it.'),
      _Status.failed => ('bajet is locked', "That didn't work. Try again, or use your phone PIN."),
      _Status.lockedOut => ('Fingerprint paused', 'Too many tries. Android has paused the fingerprint for now, so use your phone PIN.'),
      _Status.unavailable => (
          'App lock is off',
          "This phone no longer has a fingerprint or screen lock, so bajet can't check it's you. Add one in your phone's settings, then turn App lock on again in Settings."
        ),
    };
    final warn = _status == _Status.failed || _status == _Status.lockedOut;
    return UnlockExit(
      landOnToday: widget.landOnToday,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxxl, vertical: AppSpacing.xxl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // The icon's fan; while the opening plays its cards are
                  // flying here, and after an unlock they fly off it.
                  Opacity(opacity: ref.watch(openingProvider) || ref.watch(unlockFlightProvider) ? 0 : 1, child: FanMark(key: openingLockMarkKey)),
                  const SizedBox(height: AppSpacing.l),
                  // Held until the opening's cards have landed above it; an
                  // unlock holds only the screens underneath.
                  RiseIn(held: ref.watch(openingProvider) && ref.watch(entranceHoldProvider), children: [
                    Text(title, textAlign: TextAlign.center, style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: AppSpacing.s),
                    Text(body, textAlign: TextAlign.center, style: TextStyle(color: warn ? c.bad : c.muted)),
                    const SizedBox(height: AppSpacing.xxxl),
                    if (_status == _Status.unavailable)
                      Center(child: FilledButton(onPressed: () => ref.read(appLockProvider.notifier).turnOffAndOpen(), child: const Text('Open bajet')))
                    else ...[
                      if (_status != _Status.lockedOut)
                        Center(
                          child: Semantics(
                            button: true,
                            label: 'Unlock with fingerprint',
                            excludeSemantics: true,
                            child: InkResponse(
                              onTap: _busy ? null : _ask,
                              radius: 48,
                              child: AnimatedContainer(
                                duration: AppMotion.fast,
                                width: 84,
                                height: 84,
                                decoration: BoxDecoration(color: warn ? c.badSurface : c.primarySoft, shape: BoxShape.circle),
                                child: Icon(Icons.fingerprint_rounded, size: 44, color: warn ? c.bad : c.primary),
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: AppSpacing.l),
                      Center(
                        child: TextButton(
                          onPressed: _busy ? null : _ask,
                          child: Text(_status == _Status.lockedOut ? 'Use phone PIN' : 'Use phone PIN instead'),
                        ),
                      ),
                    ],
                  ]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
