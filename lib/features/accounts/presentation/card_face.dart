import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/money/money.dart';
import '../../../core/theme/app_colors.dart';
import '../domain/account_models.dart';

/// Wider than a real bank card (85.60 by 53.98 mm, about 1.59 to 1), so the
/// cards take less of the screen while still reading as cards.
const cardAspectRatio = 1.9;

const _radius = BorderRadius.all(Radius.circular(16));

/// Card faces are drawn for a 330-pixel-wide card and scaled from there, so
/// text keeps its place whatever the card's size.
const _designWidth = 330.0;

/// Text on a card follows its colour, dark on light and white on dark,
/// unless the owner picked one, such as gold on black.
Color cardInk(CardLook look) => look.ink != null ? Color(look.ink!) : inkOn(Color(look.color));

Color inkOn(Color color) => color.computeLuminance() > 0.32 ? const Color(0xFF14110A) : Colors.white;

String kindLabel(AccountKind kind) => switch (kind) {
      AccountKind.cash => 'Cash',
      AccountKind.bank => 'Bank',
      AccountKind.ewallet => 'E-wallet',
    };

/// A card's body: its colour lit from the top left, with the finish laid
/// over it. The finish never moves; the cards are still objects.
class CardSurface extends StatelessWidget {
  const CardSurface({super.key, required this.color, required this.finish, required this.child, this.shadow = true});

  final Color color;
  final CardFinish finish;
  final Widget child;
  final bool shadow;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: _radius,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color.lerp(color, Colors.white, 0.16)!, Color.lerp(color, Colors.black, 0.36)!],
          ),
          boxShadow: shadow ? const [BoxShadow(color: Color(0x99000000), blurRadius: 24, offset: Offset(0, 12), spreadRadius: -12)] : null,
        ),
        child: ClipRRect(
          borderRadius: _radius,
          child: CustomPaint(foregroundPainter: _FinishPainter(finish), child: child),
        ),
      );
}

class _FinishPainter extends CustomPainter {
  const _FinishPainter(this.finish);

  final CardFinish finish;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    switch (finish) {
      case CardFinish.brushed:
        // Fine vertical streaks, alternately lighter and darker, like
        // brushed metal.
        final light = Paint()..color = const Color(0x0FFFFFFF);
        final dark = Paint()..color = const Color(0x0D000000);
        for (var x = 0.0; x < size.width; x += 3) {
          canvas.drawRect(Rect.fromLTWH(x, 0, 1, size.height), (x ~/ 3).isEven ? light : dark);
        }
        _glow(canvas, rect, 0.10);
      case CardFinish.matte:
        _glow(canvas, rect, 0.07);
      case CardFinish.gloss:
        canvas.drawRect(
          rect,
          Paint()
            ..shader = const LinearGradient(
              begin: Alignment(-1, -0.4),
              end: Alignment(1, 0.4),
              colors: [Color(0x00FFFFFF), Color(0x4DFFFFFF), Color(0x00FFFFFF)],
              stops: [0.28, 0.40, 0.54],
            ).createShader(rect),
        );
        _glow(canvas, rect, 0.14);
      case CardFinish.leather:
        break;
    }
  }

  static void _glow(Canvas canvas, Rect rect, double strength) => canvas.drawRect(
        rect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white.withValues(alpha: strength), Colors.transparent, Colors.black.withValues(alpha: 0.12)],
          ).createShader(rect),
      );

  @override
  bool shouldRepaint(_FinishPainter old) => old.finish != finish;
}

/// One account drawn as a card: a bank or e-wallet as a card, cash as a
/// leather wallet. [back] shows the plain reverse, for a card turning over.
class AccountCard extends StatelessWidget {
  const AccountCard({super.key, required this.account, this.back = false});

  final Account account;
  final bool back;

  @override
  Widget build(BuildContext context) => AspectRatio(
        aspectRatio: cardAspectRatio,
        child: Semantics(
          label: '${account.name}${account.nickname == null ? '' : ', ${account.nickname}'}, ${Money.format(account.balance)}',
          excludeSemantics: true,
          child: account.kind == AccountKind.cash ? CashWallet(account: account, back: back) : _BankCard(account: account, back: back),
        ),
      );
}

class _BankCard extends StatelessWidget {
  const _BankCard({required this.account, required this.back});

  final Account account;
  final bool back;

  @override
  Widget build(BuildContext context) => CardSurface(
        color: Color(account.look.color),
        finish: account.look.finish,
        child: back ? const _MagneticStrip() : _CardText(account: account, contactless: account.kind == AccountKind.bank),
      );
}

class _MagneticStrip extends StatelessWidget {
  const _MagneticStrip();

  @override
  Widget build(BuildContext context) => const Align(
        alignment: Alignment(0, -0.55),
        child: FractionallySizedBox(widthFactor: 1, heightFactor: 0.18, child: ColoredBox(color: Color(0x8C000000))),
      );
}

/// The writing on a card, laid out like a real one: provider and balance at
/// the top left, the nickname where the holder's name goes, and the
/// provider again as the wordmark.
class _CardText extends StatelessWidget {
  const _CardText({required this.account, required this.contactless, this.top = 0.09});

  final Account account;
  final bool contactless;

  /// How far down the balance sits, as a share of the card's height.
  final double top;

  @override
  Widget build(BuildContext context) {
    final ink = cardInk(account.look);
    return LayoutBuilder(builder: (context, box) {
      final k = box.maxWidth / _designWidth;
      final inset = box.maxWidth * 0.065;
      TextStyle style(double size, FontWeight weight, {double opacity = 1, FontStyle? fontStyle, double? spacing}) => TextStyle(
            color: ink.withValues(alpha: opacity),
            fontSize: size * k,
            fontWeight: weight,
            fontStyle: fontStyle,
            letterSpacing: spacing,
            height: 1.1,
          );
      return Stack(children: [
        Positioned(
          left: inset,
          top: box.maxHeight * top,
          right: inset * 3,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(account.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: style(12, FontWeight.w600, opacity: 0.85)),
            SizedBox(height: 2 * k),
            FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(Money.format(account.balance), style: style(20, FontWeight.w800))),
          ]),
        ),
        if (contactless) Positioned(right: inset, top: box.maxHeight * 0.09, child: Icon(Icons.contactless_outlined, size: 26 * k, color: ink.withValues(alpha: 0.85))),
        Positioned(
          left: inset,
          bottom: box.maxHeight * 0.10,
          right: box.maxWidth * 0.5,
          child: Text(account.nickname ?? (account.kind == AccountKind.cash ? 'In your wallet' : kindLabel(account.kind)),
              maxLines: 1, overflow: TextOverflow.ellipsis, style: style(12, FontWeight.w600, opacity: 0.9, spacing: 0.4)),
        ),
        Positioned(
          right: inset,
          bottom: box.maxHeight * 0.08,
          left: box.maxWidth * 0.45,
          child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerRight, child: Text(account.name, style: style(22, FontWeight.w800, fontStyle: FontStyle.italic, spacing: -0.4))),
            Text(account.kind == AccountKind.cash ? 'NOTES AND COINS' : kindLabel(account.kind).toUpperCase(), style: style(9, FontWeight.w600, opacity: 0.75, spacing: 1)),
          ]),
        ),
      ]);
    });
  }
}

/// More money, a thicker wad: one to five bills, none when it is empty.
int billsFor(int balance) => balance <= 0 ? 0 : math.max(1, math.min(5, (math.log(balance / 100 + 1) / math.ln10 * 2).ceil()));

/// Cash: a stitched leather wallet with plain green bills sticking out of
/// the top. The bills carry no amount or artwork; they only say it is full.
class CashWallet extends StatelessWidget {
  const CashWallet({super.key, required this.account, this.back = false});

  final Account account;
  final bool back;

  static const _billLight = Color(0xFF67C473);
  static const _billDark = Color(0xFF2F8A40);

  @override
  Widget build(BuildContext context) {
    final leather = Color(account.look.color);
    return LayoutBuilder(builder: (context, box) {
      final k = box.maxWidth / _designWidth;
      final bills = back ? 0 : billsFor(account.balance);
      return Stack(clipBehavior: Clip.none, children: [
        for (var i = 0; i < bills; i++)
          Positioned(
            key: ValueKey('bill-$i'),
            top: -(5 + 4.5 * i) * k,
            left: box.maxWidth * [0.10, 0.14, 0.08, 0.12, 0.09][i],
            right: box.maxWidth * [0.13, 0.08, 0.14, 0.10, 0.12][i],
            child: Transform.rotate(
              angle: [-1.2, 1.6, -0.6, 1.0, -1.8][i] * math.pi / 180,
              child: Container(
                height: 30 * k,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3 * k),
                  gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [_billLight, _billDark]),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                  boxShadow: const [BoxShadow(color: Color(0x59000000), offset: Offset(0, 1))],
                ),
              ),
            ),
          ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: _radius,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color.lerp(leather, Colors.white, 0.10)!, Color.lerp(leather, Colors.black, 0.30)!],
              ),
              boxShadow: const [BoxShadow(color: Color(0xA6000000), blurRadius: 24, offset: Offset(0, 12), spreadRadius: -12)],
            ),
            child: CustomPaint(painter: _LeatherPainter(seed: account.id), child: const SizedBox.expand()),
          ),
        ),
        if (!back) Positioned.fill(child: _CardText(account: account, contactless: false, top: 0.17)),
      ]);
    });
  }
}

/// Leather grain, the darker lip of the pocket the bills come out of, and
/// the stitching round the edge. The grain is seeded, so it never shimmers.
class _LeatherPainter extends CustomPainter {
  const _LeatherPainter({required this.seed});

  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(seed);
    final grain = Paint();
    for (var i = 0; i < (size.width * size.height / 60).round(); i++) {
      grain.color = (random.nextBool() ? Colors.white : Colors.black).withValues(alpha: 0.035 + random.nextDouble() * 0.03);
      canvas.drawCircle(Offset(random.nextDouble() * size.width, random.nextDouble() * size.height), 0.6 + random.nextDouble(), grain);
    }
    final lip = Rect.fromLTWH(0, 0, size.width, size.height * 0.11);
    canvas.drawRRect(
      RRect.fromRectAndCorners(lip, topLeft: const Radius.circular(16), topRight: const Radius.circular(16)),
      Paint()
        ..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x47000000), Color(0x14000000)])
            .createShader(lip),
    );
    canvas.drawLine(lip.bottomLeft, lip.bottomRight, Paint()..color = const Color(0x1AFFFFFF));

    final stitch = Paint()
      ..color = const Color(0x42FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final path = Path()..addRRect(RRect.fromRectAndRadius((Offset.zero & size).deflate(7), const Radius.circular(11)));
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 8) {
        canvas.drawPath(metric.extractPath(d, d + 4), stitch);
      }
    }
  }

  @override
  bool shouldRepaint(_LeatherPainter old) => old.seed != seed;
}

/// The front of the stack: every account together. With no colour of its
/// own it takes the app's surface, light or dark.
class TotalCard extends StatelessWidget {
  const TotalCard({super.key, required this.look, required this.balance, required this.accounts, this.below, this.hint, this.countUp = false});

  final TotalCardLook look;

  /// Null while it loads.
  final int? balance;
  final List<Account> accounts;

  /// Under the balance, such as today's plan.
  final Widget? below;

  /// After the number of accounts, such as how to open them.
  final String? hint;

  /// Count up to the balance, as Today does when it opens.
  final bool countUp;

  static const _dots = 6;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final color = look.color == null ? Color.lerp(c.card, Colors.white, dark ? 0.10 : 0.55)! : Color(look.color!);
    final ink = look.color == null ? c.ink : inkOn(color);
    return AspectRatio(
      aspectRatio: cardAspectRatio,
      child: CardSurface(
        color: color,
        finish: look.finish,
        child: LayoutBuilder(builder: (context, box) {
          final k = box.maxWidth / _designWidth;
          final inset = box.maxWidth * 0.065;
          return Stack(children: [
            Positioned(
              left: inset,
              right: inset,
              top: box.maxHeight * 0.09,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                ExcludeSemantics(child: Text('Total balance', style: TextStyle(color: ink.withValues(alpha: 0.75), fontSize: 13 * k))),
                // Counts up from three quarters on arrival, and to each new
                // balance after a log, so a change is seen happening.
                TweenAnimationBuilder<double>(
                  // Starts afresh once the balance has loaded.
                  key: ValueKey(balance == null),
                  tween: Tween(begin: (balance ?? 0) * (countUp ? 0.75 : 1), end: (balance ?? 0).toDouble()),
                  duration: !countUp || MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 1400),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) => FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      balance == null ? '—' : Money.format(value.round()),
                      semanticsLabel: balance == null ? 'Total balance loading' : 'Total balance ${Money.format(balance!)}',
                      style: TextStyle(color: ink, fontSize: 38 * k, fontWeight: FontWeight.w800, letterSpacing: -0.5, height: 1.15, fontFeatures: const [FontFeature.tabularFigures()]),
                    ),
                  ),
                ),
                if (below != null) ...[SizedBox(height: 6 * k), below!],
              ]),
            ),
            Positioned(
              left: inset,
              right: inset,
              bottom: box.maxHeight * 0.09,
              child: Row(children: [
                Expanded(
                  child: Text(
                    '${accounts.length} ${accounts.length == 1 ? 'account' : 'accounts'}${hint == null ? '' : ' · $hint'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: ink.withValues(alpha: 0.8), fontSize: 12 * k),
                  ),
                ),
                for (final a in accounts.take(_dots))
                  Padding(
                    padding: EdgeInsets.only(left: 4 * k),
                    child: DecoratedBox(
                      decoration: BoxDecoration(color: Color(a.look.color), shape: BoxShape.circle, border: Border.all(color: Colors.black26)),
                      child: SizedBox.square(dimension: 9 * k),
                    ),
                  ),
                if (accounts.length > _dots)
                  Padding(
                    padding: EdgeInsets.only(left: 4 * k),
                    child: Text('+${accounts.length - _dots}', style: TextStyle(color: ink.withValues(alpha: 0.8), fontSize: 11 * k, fontWeight: FontWeight.w700)),
                  ),
              ]),
            ),
          ]);
        }),
      ),
    );
  }
}
