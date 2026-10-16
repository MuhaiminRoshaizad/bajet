import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/widgets/rise_in.dart';
import '../features/accounts/presentation/account_providers.dart';
import '../features/accounts/presentation/account_stack.dart';
import '../features/accounts/presentation/card_face.dart';
import '../features/lock/presentation/lock_providers.dart';
import '../features/opening/domain/opening_timeline.dart';
import '../features/opening/presentation/opening_providers.dart';
import '../features/opening/presentation/titanium_card.dart';
import '../features/today/presentation/today_total_card.dart';

/// Plays bajet's part of the opening over the app on a cold start
/// (docs/design-system.md, Opening). On Android 12 and later, Android's
/// splash has already dealt the cards; this picks them up exactly where it
/// left them, and only then has the splash taken away. Older phones have no
/// animated splash, so this plays the deal too. A tap anywhere skips to the
/// end; with the system's remove animations setting on, nothing moves.
class OpeningOverlay extends ConsumerStatefulWidget {
  const OpeningOverlay({super.key});

  @override
  ConsumerState<OpeningOverlay> createState() => _OpeningOverlayState();
}

class _OpeningOverlayState extends ConsumerState<OpeningOverlay> with SingleTickerProviderStateMixin {
  static double _at(double ms) => ms / OpeningTimes.end;

  late final AnimationController _clock = AnimationController(vsync: this, duration: Duration(milliseconds: OpeningTimes.end.round()))
    ..addListener(() {
      if (_clock.value >= _at(OpeningTimes.rise)) ref.read(entranceHoldProvider.notifier).release();
    })
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed) ref.read(openingProvider.notifier).finish();
    });
  OpeningPlan? _plan;
  OpeningTarget _aim = const NoTarget();
  var _aimed = false;
  var _asked = false;

  /// Until Android says whether it played the deal, nothing shows but the
  /// graphite, which is what both Android's splash and the older launch
  /// screen show too.
  var _shown = false;

  /// Android can hand over its first frame before it has said how big the
  /// screen is, so the hand-over waits for a real size, and the plan is
  /// redrawn whenever the size changes.
  OpeningPlan _planFor(Size size) {
    if (!_asked) {
      _asked = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _handOver());
    }
    final plan = _plan;
    if (plan != null && plan.size == size && plan.target == _aim) return plan;
    return _plan = OpeningPlan(size, _aim);
  }

  Future<void> _handOver() async {
    final splash = ref.read(splashHandOverProvider);
    final played = await splash.ready();
    if (!mounted) return;
    // Draw the fan where Android left it, then let Android's splash go.
    setState(() {
      _shown = true;
      _clock.value = played ? _at(OpeningTimes.dealEnd) : 0;
    });
    // A frame can finish building a moment before it reaches the screen, so
    // give the fan a couple of frames to be there before Android lets go;
    // on the phone, one frame was not enough and a blank frame flashed.
    for (var i = 0; i < 3; i++) {
      await WidgetsBinding.instance.endOfFrame;
      if (mounted) WidgetsBinding.instance.scheduleFrame();
    }
    await splash.remove();
    if (!mounted) return;
    if (MediaQuery.disableAnimationsOf(context)) return _skip();
    _clock.forward();
  }

  void _skip() => ref.read(openingProvider.notifier).finish();

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
        if (size.isEmpty) return const ColoredBox(color: graphite);
        _planFor(size);
        if (!_shown) return const ColoredBox(color: graphite);
        return Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (_) => _skip(),
          child: AnimatedBuilder(
            animation: _clock,
            builder: (context, _) {
              final ms = _clock.value * OpeningTimes.end;
              if (!_aimed && ms >= OpeningTimes.fly) {
                _aimed = true;
                _aim = _target();
              }
              return _Frame(plan: _planFor(size), ms: ms, base: size.width - 32);
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
            if (titanium > 0) Opacity(opacity: titanium.clamp(0, 1), child: TitaniumCard(depth: i, width: base)),
            if (real != null && shown > 0) Opacity(opacity: shown.clamp(0, 1), child: real),
          ]),
        ),
      ),
    );
  }

  /// "bajet" under the fan, each letter rising from behind its own line, and
  /// the titanium line beneath it.
  List<Widget> _word() {
    const style = wordmarkStyle;
    final line = plan.lineAt(ms);
    final x0 = plan.size.width / 2 - OpeningPlan.lineWidth / 2;
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
                    offset: Offset(0, letter.drop * wordmarkStyle.fontSize!),
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
          width: OpeningPlan.lineWidth,
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
    ];
  }
}
