import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../domain/account_models.dart';
import 'card_face.dart';
import 'hold_swell.dart';

/// Where each card sits on Your accounts. At rest the cards overlap like a
/// wallet, each showing a strip with its name and balance. Scrolling opens
/// them downward: the list is held still while the first [open] pixels of
/// scroll go into spreading the cards below the top one apart, until each
/// card is whole with a [gap] beneath it. Past that the page scrolls as a
/// plain list.
class AccountListLayout {
  const AccountListLayout({required this.accounts, required this.width});

  final List<Account> accounts;
  final double width;

  static const strip = 74.0;
  static const gap = 14.0;

  /// How far a scroll opens the cards fully.
  static const open = 220.0;

  /// Room a cash wallet's bills need above it, so they never cover the
  /// balance of the card before.
  static const billRoom = 26.0;

  double get cardHeight => width / cardAspectRatio;

  double _bills(int i) => i < accounts.length && accounts[i].kind == AccountKind.cash ? billRoom : 0;

  /// From card [i]'s top to the next card's, closed and fully open.
  double _closed(int i) => strip + _bills(i + 1);
  double _opened(int i) => cardHeight + gap + _bills(i + 1);

  /// How open the cards are at a scroll [offset], 0 to 1.
  static double openness(double offset) => (offset / open).clamp(0.0, 1.0);

  /// Card [i]'s top within the list, at scroll [offset], with [arrived] how
  /// far the arrival has run, 0 to 1: from all on top of each other to their
  /// strips.
  double top(int i, double offset, {double arrived = 1}) {
    final p = openness(offset);
    var y = offset.clamp(0.0, open) + _bills(0);
    for (var j = 0; j < i; j++) {
      y += _arrival(j, arrived) * (_closed(j) + (_opened(j) - _closed(j)) * p);
    }
    return y;
  }

  /// Each card's own stretch of the arrival, a little after the one above,
  /// sprung so it overshoots and settles; exactly 1 once the arrival ends.
  double _arrival(int j, double arrived) {
    if (arrived >= 1) return 1;
    final step = accounts.length < 2 ? 0.0 : 0.3 / (accounts.length - 1);
    final local = ((arrived - step * j) / (1 - step * (accounts.length - 1))).clamp(0.0, 1.0);
    return Curves.easeOutBack.transform(local);
  }

  /// The list's full height: the open cards, plus the scroll that opens them.
  double get height {
    if (accounts.isEmpty) return 0;
    var y = open + _bills(0);
    for (var j = 0; j < accounts.length - 1; j++) {
      y += _opened(j);
    }
    return y + cardHeight;
  }
}

/// The cards laid out by [AccountListLayout] for the current scroll. Held
/// until the firmer tick, a card is picked up and can be dragged up or down:
/// the others slide out of its way with a click each, a dashed outline shows
/// where it will land, and letting go saves the new order ([onReorder]).
class AccountList extends StatefulWidget {
  const AccountList({
    super.key,
    required this.accounts,
    required this.offset,
    this.arrived = 1,
    this.onTap,
    this.onReorder,
    this.hidden = const {},
  });

  final List<Account> accounts;
  final double offset;
  final double arrived;
  final ValueChanged<Account>? onTap;

  /// Every account's id in the order the user dragged them into.
  final ValueChanged<List<int>>? onReorder;

  /// Accounts whose cards are in flight elsewhere, so they hold their place
  /// unseen and never show twice.
  final Set<int> hidden;

  @override
  State<AccountList> createState() => _AccountListState();
}

class _AccountListState extends State<AccountList> {
  /// The order while a card is being dragged, and after it is let go until
  /// the saved order comes back.
  List<int>? _order;
  int? _dragged;

  /// The dragged card's top when it was picked up, and the finger's travel.
  double _from = 0, _dy = 0;

  static const _slide = Duration(milliseconds: 220);

  static String _key(Iterable<int> ids) => ids.join(',');

  List<Account> get _accounts {
    final order = _order;
    if (order == null) return widget.accounts;
    final byId = {for (final a in widget.accounts) a.id: a};
    // Accounts added or gone meanwhile: the saved list is the truth.
    if (order.length != byId.length || !order.every(byId.containsKey)) return widget.accounts;
    return [for (final id in order) byId[id]!];
  }

  @override
  void didUpdateWidget(AccountList old) {
    super.didUpdateWidget(old);
    // The saved order has arrived: nothing left to hold on to.
    if (_dragged == null && _order != null && _key(widget.accounts.map((a) => a.id)) == _key(_order!)) _order = null;
  }

  void _pickUp(AccountListLayout layout, Account a) {
    setState(() {
      _order = [for (final x in _accounts) x.id];
      _dragged = a.id;
      _from = layout.top(_order!.indexOf(a.id), widget.offset);
      _dy = 0;
    });
  }

  void _drag(double width, Offset travel) {
    final order = _order;
    final id = _dragged;
    if (order == null || id == null) return;
    final byId = {for (final a in _accounts) a.id: a};
    final top = _from + travel.dy;
    // The slot whose top is nearest the card's, trying the card in each.
    var best = order.indexOf(id);
    var bestGap = double.infinity;
    for (var i = 0; i < order.length; i++) {
      final trial = [...order]
        ..remove(id)
        ..insert(i, id);
      final gap = (AccountListLayout(accounts: [for (final x in trial) byId[x]!], width: width).top(i, widget.offset) - top).abs();
      if (gap < bestGap) (best, bestGap) = (i, gap);
    }
    setState(() {
      _dy = travel.dy;
      if (best != order.indexOf(id)) {
        HapticFeedback.selectionClick();
        _order = [...order]
          ..remove(id)
          ..insert(best, id);
      }
    });
  }

  void _drop() {
    final order = _order;
    setState(() => _dragged = null);
    if (order == null) return;
    if (_key(order) != _key(widget.accounts.map((a) => a.id))) {
      widget.onReorder?.call(order);
    } else {
      _order = null;
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final accounts = _accounts;
        final layout = AccountListLayout(accounts: accounts, width: box.maxWidth);
        final dragging = _dragged != null;
        final slot = accounts.indexWhere((a) => a.id == _dragged);
        Widget card(int i, Account a) {
          final held = a.id == _dragged;
          return AnimatedPositioned(
            key: ValueKey('account-card-${a.id}'),
            // Following the scroll or the finger is immediate; sliding out of
            // the way, or into the slot when let go, is not.
            duration: held || _order == null ? Duration.zero : _slide,
            curve: Curves.easeOutCubic,
            top: held
                ? (_from + _dy).clamp(layout.top(0, widget.offset) - 20, layout.top(accounts.length - 1, widget.offset) + 20)
                : layout.top(i, widget.offset, arrived: widget.arrived),
            left: 0,
            width: box.maxWidth,
            child: Opacity(
              opacity: widget.hidden.contains(a.id) ? 0 : 1,
              child: _Dim(
                on: dragging && !held,
                child: HoldSwell(
                  onTap: widget.onTap == null ? null : () => widget.onTap!(a),
                  onPickUp: widget.onReorder == null || accounts.length < 2 ? null : () => _pickUp(layout, a),
                  onDrag: (travel) => _drag(box.maxWidth, travel),
                  onDrop: _drop,
                  // Scrolling turns the cards a little, so a mirror or pearl
                  // card's shine slides as the finger drags the list.
                  child: AccountCard(account: a, tilt: (widget.offset / 300 - 0.15 * i).clamp(-1.0, 1.0)),
                ),
              ),
            ),
          );
        }

        return SizedBox(
          height: layout.height,
          child: Stack(clipBehavior: Clip.none, children: [
            // Later cards overlap the bottom of the one above; the card being
            // dragged rides over them all, above the outline of its slot.
            for (final (i, a) in accounts.indexed)
              if (a.id != _dragged) card(i, a),
            if (dragging)
              Positioned(
                top: layout.top(slot, widget.offset),
                left: 0,
                width: box.maxWidth,
                height: slot == accounts.length - 1 ? layout.cardHeight : AccountListLayout.strip,
                child: const IgnorePointer(child: _Slot()),
              ),
            for (final (i, a) in accounts.indexed)
              if (a.id == _dragged) card(i, a),
          ]),
        );
      });
}

/// The cards not being dragged, a little darker, so the one held stands out.
class _Dim extends StatelessWidget {
  const _Dim({required this.on, required this.child});

  final bool on;
  final Widget child;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(end: on ? 0.82 : 1),
        duration: const Duration(milliseconds: 180),
        builder: (context, k, child) => k == 1
            ? child!
            : ColorFiltered(
                colorFilter: ColorFilter.matrix([k, 0, 0, 0, 0, 0, k, 0, 0, 0, 0, 0, k, 0, 0, 0, 0, 0, 1, 0]),
                child: child,
              ),
        child: child,
      );
}

/// Where the card being dragged will land: a dashed outline in the card's
/// shape.
class _Slot extends StatelessWidget {
  const _Slot();

  @override
  Widget build(BuildContext context) => CustomPaint(painter: _DashedOutline(context.colors.muted.withValues(alpha: 0.6)));
}

class _DashedOutline extends CustomPainter {
  const _DashedOutline(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final outline = Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(16)));
    for (final metric in outline.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 10) {
        canvas.drawPath(metric.extractPath(d, d + 5), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedOutline old) => old.color != color;
}
