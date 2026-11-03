import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_sheet.dart';

/// What can be done to a message held in the chat.
enum MessageAction { copy, select }

/// Holding a message: the chat dims, the message lifts out of it (rising a
/// little when it sits too low for the menu), and the menu springs out
/// beneath it, its rows following one after another. [bubble] is drawn
/// again at the held message's place, [at].
Future<MessageAction?> showMessageMenu(BuildContext context, {required Widget bubble, required Rect at, required bool mine}) {
  HapticFeedback.mediumImpact();
  return Navigator.of(context).push(_MessageMenuRoute(bubble: bubble, at: at, mine: mine));
}

/// Opens [text] on its own, so any part of it can be chosen and copied.
Future<void> showSelectText(BuildContext context, String text) => showAppSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final c = context.colors;
        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.7),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.l, AppSpacing.xl, AppSpacing.xl),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Select text', style: TextStyle(color: c.muted, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
              const SizedBox(height: AppSpacing.m),
              SelectableText(text, key: const ValueKey('select-text'), style: TextStyle(color: c.ink, height: 1.5)),
            ]),
          ),
        );
      },
    );

class _MessageMenuRoute extends PopupRoute<MessageAction> {
  _MessageMenuRoute({required this.bubble, required this.at, required this.mine});

  final Widget bubble;
  final Rect at;
  final bool mine;

  static const _rows = [
    (MessageAction.copy, Icons.copy_rounded, 'Copy'),
    (MessageAction.select, Icons.text_fields_rounded, 'Select text'),
  ];
  static const _rowHeight = 48.0;
  static const _menuWidth = 208.0;

  @override
  Color? get barrierColor => Colors.black.withValues(alpha: 0.5);

  @override
  bool get barrierDismissible => true;

  @override
  String get barrierLabel => 'Close the menu';

  @override
  Duration get transitionDuration => const Duration(milliseconds: 420);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 200);

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    final c = context.colors;
    final still = MediaQuery.disableAnimationsOf(context);
    final run = still ? kAlwaysCompleteAnimation : animation;
    final screen = MediaQuery.sizeOf(context);
    final menuHeight = _rows.length * _rowHeight + AppSpacing.s * 2;
    // A message too low for its menu rises just enough to show it whole.
    final room = screen.height - MediaQuery.paddingOf(context).bottom - AppSpacing.l;
    final lift = math.max(0.0, at.bottom + AppSpacing.s + menuHeight - room);
    final rise = CurvedAnimation(parent: run, curve: Curves.easeOutBack, reverseCurve: Curves.easeInCubic);
    return AnimatedBuilder(
      animation: rise,
      builder: (context, _) {
        final up = lift * rise.value;
        return Stack(children: [
          Positioned(
            left: at.left,
            top: at.top - up,
            width: at.width,
            child: IgnorePointer(
              child: Transform.scale(
                scale: 1 + 0.02 * rise.value,
                alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                child: Material(type: MaterialType.transparency, child: bubble),
              ),
            ),
          ),
          Positioned(
            top: at.bottom - up + AppSpacing.s,
            left: mine ? null : at.left,
            right: mine ? screen.width - at.right : null,
            width: _menuWidth,
            child: Transform.scale(
              scale: 0.6 + 0.4 * rise.value,
              alignment: mine ? Alignment.topRight : Alignment.topLeft,
              child: Opacity(
                opacity: run.value.clamp(0.0, 1.0),
                child: Material(
                  key: const ValueKey('message-menu'),
                  color: c.raised,
                  elevation: 10,
                  shadowColor: c.shade,
                  borderRadius: BorderRadius.circular(18),
                  clipBehavior: Clip.antiAlias,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      for (final (i, (action, icon, label)) in _rows.indexed)
                        _Row(
                          animation: run,
                          start: 0.15 + 0.1 * i,
                          child: InkWell(
                            onTap: () => Navigator.of(context).pop(action),
                            child: SizedBox(
                              height: _rowHeight,
                              child: Row(children: [
                                const SizedBox(width: AppSpacing.l),
                                Icon(icon, size: 20, color: c.ink),
                                const SizedBox(width: AppSpacing.m),
                                Text(label, style: TextStyle(color: c.ink, fontWeight: FontWeight.w600)),
                              ]),
                            ),
                          ),
                        ),
                    ]),
                  ),
                ),
              ),
            ),
          ),
        ]);
      },
    );
  }

  // The page animates itself, so the route adds nothing on top.
  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) => child;
}

/// A row fading and springing down into place, a little after the one above.
class _Row extends StatelessWidget {
  const _Row({required this.animation, required this.start, required this.child});

  final Animation<double> animation;
  final double start;
  final Widget child;

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Interval(start, math.min(1, start + 0.35))),
        child: SlideTransition(
          position: Tween(begin: const Offset(0, -0.3), end: Offset.zero)
              .animate(CurvedAnimation(parent: animation, curve: Interval(start, math.min(1, start + 0.5), curve: Curves.easeOutBack))),
          child: child,
        ),
      );
}
