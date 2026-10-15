import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/money/money.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../domain/account_models.dart';
import 'account_providers.dart';
import 'card_designer.dart';
import 'card_face.dart';
import 'move_money_sheet.dart';

/// Where each account's card sits on the page it was opened from, so the card
/// can fly out of its place and back into it, whichever account is showing
/// by then.
typedef CardPlaces = Rect? Function(int accountId);

/// One account at a time, its card stood upright, swiping to the next. The
/// tapped card flies up from the stack and turns upright as the page comes
/// in, then the name, balance and the rest follow.
class AccountViewScreen extends ConsumerStatefulWidget {
  const AccountViewScreen({super.key, required this.accountId, this.places});

  final int accountId;
  final CardPlaces? places;

  /// The whole arrival: the flight takes the first 300 ms of it.
  static const duration = Duration(milliseconds: 700);
  static const reverseDuration = Duration(milliseconds: 300);

  @override
  ConsumerState<AccountViewScreen> createState() => _AccountViewScreenState();
}

/// The swipe, tuned against the motion study: a card coming in from the
/// right spins once ([spin] turns per page), shown through a slight
/// perspective; every card off centre shrinks and fades.
abstract final class _Swipe {
  static const viewport = 0.70;
  static const spin = 1.0;
  static const perspective = 0.0015;
  static const sideScale = 0.15;
  static const sideFade = 0.4;
}

class _AccountViewScreenState extends ConsumerState<AccountViewScreen> {
  PageController? _pages;
  final _carousel = GlobalKey();
  int _index = 0;

  @override
  void dispose() {
    _pages?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(accountsProvider).value;
    if (accounts == null || accounts.isEmpty) return const Scaffold();
    if (_pages == null) {
      _index = math.max(0, accounts.indexWhere((a) => a.id == widget.accountId));
      _pages = PageController(viewportFraction: _Swipe.viewport, initialPage: _index);
    }
    final route = ModalRoute.of(context)!.animation!;
    final c = context.colors;
    // Arriving, each part comes in at its own moment; leaving, they all go in
    // the first half, while the card is still on its way home.
    Animation<double> part(double from, double to) =>
        CurvedAnimation(parent: route, curve: Interval(from, to, curve: Curves.easeOut), reverseCurve: const Interval(0.5, 1, curve: Curves.easeIn));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(children: [
        // The wash over the page underneath, lifting as the card flies home.
        Positioned.fill(
          child: FadeTransition(
            opacity: CurvedAnimation(parent: route, curve: const Interval(0, 0.43, curve: Curves.easeOut), reverseCurve: Curves.easeIn),
            child: ColoredBox(color: c.background),
          ),
        ),
        SafeArea(
          child: Column(children: [
            FadeTransition(
              opacity: part(0.43, 0.71),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.s, AppSpacing.s, AppSpacing.s, 0),
                child: Row(children: [
                  BackButton(onPressed: () => Navigator.of(context).maybePop()),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Edit this card',
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => showCardDesigner(context, accounts[_index.clamp(0, accounts.length - 1)]),
                  ),
                ]),
              ),
            ),
            FadeTransition(opacity: part(0.43, 0.71), child: _Titles(pages: _pages!, accounts: accounts)),
            FadeTransition(opacity: part(0.43, 0.71), child: _BalanceLine(account: accounts[_index.clamp(0, accounts.length - 1)])),
            Expanded(
              child: LayoutBuilder(
                key: _carousel,
                builder: (context, box) => PageView.builder(
                  controller: _pages,
                  itemCount: accounts.length,
                  onPageChanged: (i) {
                    HapticFeedback.selectionClick();
                    setState(() => _index = i);
                  },
                  itemBuilder: (context, i) => AnimatedBuilder(
                    animation: Listenable.merge([_pages!, route]),
                    builder: (context, _) {
                      final page = _pages!.hasClients && _pages!.position.haveDimensions ? _pages!.page! : _index.toDouble();
                      // The tapped card is the flyer until it has landed.
                      final flying = widget.places != null && i == _index && route.status != AnimationStatus.completed;
                      return Opacity(
                        opacity: flying ? 0 : (i == _index ? 1 : part(0.07, 0.43).value),
                        child: _SwipeCard(account: accounts[i], t: i - page, size: _cardSize(box.biggest)),
                      );
                    },
                  ),
                ),
              ),
            ),
            FadeTransition(
              opacity: part(0.57, 1),
              child: Column(children: [
                _Dots(pages: _pages!, count: accounts.length),
                // Moving money needs somewhere to move it to.
                if (accounts.length > 1)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.l, AppSpacing.l, AppSpacing.l, 0),
                    child: SizedBox(
                      width: double.infinity,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: FilledButton(
                          key: ValueKey(accounts[_index.clamp(0, accounts.length - 1)].id),
                          onPressed: () => showMoveMoney(context, fromId: accounts[_index.clamp(0, accounts.length - 1)].id),
                          child: Text('Move money from ${accounts[_index.clamp(0, accounts.length - 1)].name}', maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ),
                  ),
              ]),
            ),
            const SizedBox(height: AppSpacing.xxl),
          ]),
        ),
        if (widget.places != null) _Flyer(account: accounts[_index.clamp(0, accounts.length - 1)], places: widget.places!, carousel: _carousel, route: route, size: _cardSize),
      ]),
    );
  }

  /// Upright, the card's short side is 62% of the screen's width, shrunk to
  /// fit a short screen.
  static Size _cardSize(Size area) {
    final short = math.min(area.width * 0.62, area.height * 0.86 / cardAspectRatio);
    return Size(short, short * cardAspectRatio);
  }
}

/// A card on the swipe, at [t] pages from the centre: positive to the right.
class _SwipeCard extends StatelessWidget {
  const _SwipeCard({required this.account, required this.t, required this.size});

  final Account account;
  final double t;
  final Size size;

  @override
  Widget build(BuildContext context) {
    final a = t.abs();
    // Only a card coming in from the right turns; one leaving to the left
    // just slides away. Swiping back plays the turn in reverse.
    final angle = t > 0 ? t * 2 * math.pi * _Swipe.spin : 0.0;
    final scale = math.max(0.0, 1 - _Swipe.sideScale * a);
    return Center(
      child: Opacity(
        opacity: (1 - _Swipe.sideFade * a).clamp(0.0, 1.0),
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, _Swipe.perspective)
            ..rotateY(angle)
            ..scaleByDouble(scale, scale, 1, 1),
          // Past a quarter turn the front faces away; show the plain back,
          // never the front's writing mirrored.
          child: _Upright(account: account, size: size, back: math.cos(angle) < 0),
        ),
      ),
    );
  }
}

/// A landscape card turned a quarter clockwise, so it reads top to bottom.
class _Upright extends StatelessWidget {
  const _Upright({required this.account, required this.size, this.back = false});

  final Account account;
  final Size size;
  final bool back;

  @override
  Widget build(BuildContext context) => SizedBox.fromSize(
        size: size,
        child: RotatedBox(quarterTurns: 1, child: AccountCard(account: account, back: back)),
      );
}

/// The card on its way between its place in the stack and the middle of this
/// page: it turns from flat to upright and grows a little, with no
/// overshoot.
class _Flyer extends StatelessWidget {
  const _Flyer({required this.account, required this.places, required this.carousel, required this.route, required this.size});

  final Account account;
  final CardPlaces places;
  final GlobalKey carousel;
  final Animation<double> route;
  final Size Function(Size area) size;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: route,
        builder: (context, _) {
          final from = places(account.id);
          final area = carousel.currentContext?.findRenderObject() as RenderBox?;
          if (from == null || area == null || !area.hasSize || route.status == AnimationStatus.completed) return const SizedBox.shrink();
          final upright = size(area.size);
          final centre = area.localToGlobal(area.size.center(Offset.zero));
          // Out, the flight is the first part of the arrival; home, it is the
          // whole of the leaving.
          final k = route.status == AnimationStatus.reverse
              ? Curves.fastOutSlowIn.transform(route.value)
              : Curves.fastOutSlowIn.transform((route.value / 0.43).clamp(0.0, 1.0));
          // Lying flat the card is as wide as in the stack; upright, its long
          // side is the upright card's height.
          final grow = upright.height / from.width;
          final mid = Offset.lerp(from.center, centre, k)!;
          return Positioned(
            left: mid.dx - from.width / 2,
            top: mid.dy - from.height / 2,
            width: from.width,
            height: from.height,
            child: IgnorePointer(
              child: Transform.rotate(
                angle: k * math.pi / 2,
                child: Transform.scale(scale: 1 + (grow - 1) * k, child: AccountCard(account: account)),
              ),
            ),
          );
        },
      );
}

/// The account names in a strip that moves with the swipe: the centred one
/// large, its neighbours faded at the edges.
class _Titles extends StatelessWidget {
  const _Titles({required this.pages, required this.accounts});

  final PageController pages;
  final List<Account> accounts;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 44,
        child: AnimatedBuilder(
          animation: pages,
          builder: (context, _) {
            final page = pages.hasClients && pages.position.haveDimensions ? pages.page! : pages.initialPage.toDouble();
            return LayoutBuilder(
              builder: (context, box) => Stack(clipBehavior: Clip.hardEdge, children: [
                for (final (i, a) in accounts.indexed)
                  if ((i - page).abs() < 1.6)
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 0,
                      child: Transform.translate(
                        offset: Offset((i - page) * box.maxWidth * 0.42, 0),
                        child: Opacity(
                          opacity: _fade((i - page).abs()),
                          child: Text(a.name, textAlign: TextAlign.center, maxLines: 1, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
                        ),
                      ),
                    ),
              ]),
            );
          },
        ),
      );

  /// Full in the middle, a quarter at a neighbour's place, gone beyond.
  static double _fade(double a) => a <= 1 ? 1 - 0.75 * a : math.max(0, 0.25 * (1.6 - a) / 0.6);
}

/// The centred account's balance and nickname. It changes once the swipe is
/// past halfway: the old one fades out, the new one in.
class _BalanceLine extends StatelessWidget {
  const _BalanceLine({required this.account});

  final Account account;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox(
      height: 26,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 150),
        child: Text.rich(
          key: ValueKey(account.id),
          TextSpan(children: [
            TextSpan(text: Money.format(account.balance), style: TextStyle(fontWeight: FontWeight.w700, color: account.balance < 0 ? c.bad : c.ink)),
            TextSpan(text: ' · ${account.nickname ?? kindLabel(account.kind)}', style: TextStyle(color: c.muted)),
          ]),
          style: const TextStyle(fontSize: 15),
        ),
      ),
    );
  }
}

/// One dot per account; the centred one is a wide pill that slides along.
class _Dots extends StatelessWidget {
  const _Dots({required this.pages, required this.count});

  final PageController pages;
  final int count;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AnimatedBuilder(
      animation: pages,
      builder: (context, _) {
        final page = pages.hasClients && pages.position.haveDimensions ? pages.page! : pages.initialPage.toDouble();
        return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          for (var i = 0; i < count; i++)
            () {
              final k = math.max(0.0, 1 - (i - page).abs());
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 2.5),
                width: 6 + 14 * k,
                height: 6,
                decoration: BoxDecoration(color: c.ink.withValues(alpha: 0.25 + 0.6 * k), borderRadius: BorderRadius.circular(3)),
              );
            }(),
        ]);
      },
    );
  }
}
