import 'package:flutter/material.dart';

import '../../../core/money/money.dart';
import '../../../core/theme/app_colors.dart';
import '../domain/account_models.dart';

/// A bank card's shape, 85.60 by 53.98 mm (ISO/IEC 7810 ID-1).
const cardAspectRatio = 85.6 / 53.98;

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

/// One account drawn as a card. [back] shows the plain reverse, for a card
/// turning over.
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
          child: _BankCard(account: account, back: back),
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
  const _CardText({required this.account, required this.contactless});

  final Account account;
  final bool contactless;

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
          top: box.maxHeight * 0.09,
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

/// The front of the stack: every account together. With no colour of its
/// own it takes the app's surface, light or dark.
class TotalCard extends StatelessWidget {
  const TotalCard({super.key, required this.look, required this.balance, required this.accounts, this.below, this.hint});

  final TotalCardLook look;
  final int balance;
  final List<Account> accounts;

  /// Under the balance, such as today's plan.
  final Widget? below;

  /// After the number of accounts, such as how to open them.
  final String? hint;

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
                Text('Total balance', style: TextStyle(color: ink.withValues(alpha: 0.75), fontSize: 13 * k)),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(Money.format(balance), style: TextStyle(color: ink, fontSize: 38 * k, fontWeight: FontWeight.w800, letterSpacing: -0.5, height: 1.15)),
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
