import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/accounts/presentation/account_providers.dart';
import '../features/accounts/presentation/account_stack.dart';
import '../features/accounts/presentation/card_face.dart';
import '../features/lock/presentation/lock_providers.dart';
import '../features/opening/domain/opening_timeline.dart';
import '../features/opening/presentation/opening_providers.dart';
import '../features/opening/presentation/titanium_card.dart';
import '../features/today/presentation/today_total_card.dart';

/// Plays the opening over the app on a cold start (docs/design-system.md,
/// Opening). A tap anywhere skips to the end; with the system's remove
/// animations setting on, it does not play at all.
class OpeningOverlay extends ConsumerStatefulWidget {
  const OpeningOverlay({super.key});

  @override
  ConsumerState<OpeningOverlay> createState() => _OpeningOverlayState();
}

class _OpeningOverlayState extends ConsumerState<OpeningOverlay> with SingleTickerProviderStateMixin {
  late final _clock = AnimationController(vsync: this, duration: Duration(milliseconds: OpeningTimes.end.round()))
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed) ref.read(openingProvider.notifier).finish();
    });
  OpeningPlan? _plan;
  var _aimed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_clock.isAnimating || _clock.isCompleted) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => ref.read(openingProvider.notifier).finish(skipped: true));
    } else {
      _clock.forward();
    }
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  /// Where the cards land, looked up as they take off, once the screen
  /// underneath has had time to lay out.
  OpeningTarget _target() {
    if (ref.read(appLockProvider)) {
      final mark = openingLockMarkKey.currentContext?.findRenderObject() as RenderBox?;
      if (mark != null && mark.hasSize) return LockTarget(mark.localToGlobal(mark.size.center(Offset.zero)));
      return const NoTarget();
    }
    final stack = openingStackKey.currentContext?.findRenderObject() as RenderBox?;
    final count = ref.read(accountsProvider).value?.length ?? 0;
    if (stack == null || !stack.hasSize || count == 0) return const NoTarget();
    final places = StackPlaces(stack.localToGlobal(Offset.zero) & stack.size, count);
    return StackTarget(places.card(1), places.card(0), places.total);
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final size = box.biggest;
        return Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (_) => ref.read(openingProvider.notifier).finish(skipped: true),
          child: AnimatedBuilder(
            animation: _clock,
            builder: (context, _) {
              final ms = _clock.value * OpeningTimes.end;
              if (!_aimed && ms >= OpeningTimes.fly) {
                _aimed = true;
                _plan = OpeningPlan(size, _target());
              }
              final plan = _plan ??= OpeningPlan(size, const NoTarget());
              return _Frame(plan: plan, ms: ms, base: size.width - 32);
            },
          ),
        );
      });
}

/// The opening at one moment.
class _Frame extends ConsumerWidget {
  const _Frame({required this.plan, required this.ms, required this.base});

  final OpeningPlan plan;
  final double ms;

  /// The width every card is drawn at before it is scaled: Today's.
  final double base;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(accountsProvider).value ?? const [];
    Widget? real(int i) => switch (i) {
          _ when plan.target is! StackTarget || accounts.isEmpty => null,
          2 => const TodayTotalCard(),
          _ => AccountCard(account: accounts[math.min(1 - i, accounts.length - 1)]),
        };
    // Above the navigator there is no Material for text to take its style
    // from, so the overlay brings its own.
    return ExcludeSemantics(
      child: Material(
        type: MaterialType.transparency,
        child: Stack(clipBehavior: Clip.none, children: [
          Positioned.fill(child: ColoredBox(color: graphite.withValues(alpha: plan.backdropAt(ms)))),
          for (var i = 0; i < 3; i++) _card(i, real(i)),
          ..._word(),
        ]),
      ),
    );
  }

  Widget _card(int i, Widget? real) {
    final pose = plan.card(i, ms);
    final h = base / cardAspectRatio;
    final titanium = plan.titanium(i, ms), shown = plan.real(i, ms);
    return Positioned(
      left: pose.centre.dx - base / 2,
      top: pose.centre.dy - h / 2,
      width: base,
      height: h,
      child: Opacity(
        opacity: pose.opacity.clamp(0, 1),
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.rotationZ(pose.turn * math.pi / 180)..scaleByDouble(pose.width / base, pose.width / base, 1, 1),
          child: Stack(children: [
            if (titanium > 0) Opacity(opacity: titanium.clamp(0, 1), child: TitaniumCard(depth: i, width: base, sheen: i == 2 ? plan.sheenAt(ms) : null)),
            if (real != null && shown > 0) Opacity(opacity: shown.clamp(0, 1), child: real),
          ]),
        ),
      ),
    );
  }

  /// "bajet" under the fan, each letter rising from behind its own line, and
  /// the titanium line beneath it with its point of light.
  List<Widget> _word() {
    const style = TextStyle(fontSize: 34, height: 1, fontWeight: FontWeight.w800, letterSpacing: .68, color: Color(0xFFE3E9EE));
    final line = plan.lineAt(ms), spark = plan.sparkAt(ms), sparkOpacity = plan.sparkOpacityAt(ms) * line;
    final x0 = plan.size.width / 2 - 66;
    return [
      Positioned(
        top: plan.wordTop,
        left: 0,
        right: 0,
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          for (final (i, l) in 'bajet'.split('').indexed)
            Builder(builder: (context) {
              final letter = plan.letter(i, ms);
              Widget glyph = Text(l, style: style, textScaler: TextScaler.noScaling);
              if (letter.blur > 0.01) glyph = ImageFiltered(imageFilter: ImageFilter.blur(sigmaX: letter.blur, sigmaY: letter.blur), child: glyph);
              return ClipRect(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: .5),
                  child: Transform.translate(
                    offset: Offset(0, letter.drop * 34),
                    child: Opacity(opacity: letter.opacity.clamp(0, 1), child: glyph),
                  ),
                ),
              );
            }),
        ]),
      ),
      if (line > 0)
        Positioned(
          top: plan.lineTop,
          left: x0,
          width: 132,
          height: 2,
          child: Opacity(
            opacity: line.clamp(0, 1),
            child: Transform.scale(
              scaleX: line,
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(2)),
                  gradient: LinearGradient(colors: [Color(0x00D8DBDF), Color(0xFFD8DBDF), Color(0xFFD8DBDF), Color(0x00D8DBDF)], stops: [0, .3, .7, 1]),
                ),
              ),
            ),
          ),
        ),
      if (sparkOpacity > 0)
        Positioned(
          // The point rides on the line, so it is squeezed towards the
          // middle while the line is still drawing out.
          top: plan.lineTop - 3,
          left: plan.size.width / 2 + (spark * 132 - 66) * line - 4,
          width: 8,
          height: 8,
          child: Opacity(
            opacity: sparkOpacity.clamp(0, 1),
            child: const DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Color(0x8CFFFFFF), blurRadius: 10, spreadRadius: 3)],
              ),
            ),
          ),
        ),
    ];
  }
}
