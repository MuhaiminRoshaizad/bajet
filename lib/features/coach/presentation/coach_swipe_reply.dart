import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';

/// Swipe a message right to reply to it: it follows the finger, giving
/// less past the reach, while a reply mark grows behind it and lights up
/// with a tick at the point of no return. Let go and it springs home,
/// replying if it got that far.
class SwipeToReply extends StatefulWidget {
  const SwipeToReply({super.key, required this.onReply, required this.child});

  final VoidCallback onReply;
  final Widget child;

  @override
  State<SwipeToReply> createState() => _SwipeToReplyState();
}

class _SwipeToReplyState extends State<SwipeToReply> with SingleTickerProviderStateMixin {
  static const _reach = 64.0;
  late final _dx = AnimationController.unbounded(vsync: this);

  @override
  void dispose() {
    _dx.dispose();
    super.dispose();
  }

  void _drag(DragUpdateDetails d) {
    final before = _dx.value;
    final raw = before + d.delta.dx;
    // Past the reach it gives only a quarter as much.
    _dx.value = raw <= _reach ? (raw < 0 ? 0 : raw) : _reach + (raw - _reach) * 0.25;
    if (before < _reach && _dx.value >= _reach) unawaited(HapticFeedback.selectionClick());
  }

  void _release(DragEndDetails d) {
    if (_dx.value >= _reach) widget.onReply();
    if (MediaQuery.disableAnimationsOf(context)) {
      _dx.value = 0;
    } else {
      _dx.animateWith(SpringSimulation(AppMotion.spring, _dx.value, 0, d.primaryVelocity ?? 0));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onHorizontalDragUpdate: _drag,
      onHorizontalDragEnd: _release,
      child: AnimatedBuilder(
        animation: _dx,
        builder: (context, child) {
          final pull = (_dx.value / _reach).clamp(0.0, 1.0);
          final ready = pull >= 1;
          return Stack(clipBehavior: Clip.none, alignment: Alignment.centerLeft, children: [
            // The mark is there only while the message is pulled.
            if (pull > 0)
              Positioned(
                left: 0,
                child: Opacity(
                  opacity: pull,
                  child: Transform.scale(
                    scale: 0.4 + 0.6 * Curves.easeOutBack.transform(pull),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: ready ? c.primary : c.well,
                        boxShadow: ready ? [BoxShadow(color: c.primary.withValues(alpha: 0.5), blurRadius: 14)] : null,
                      ),
                      child: Icon(Icons.reply_rounded, size: 20, color: ready ? c.onPrimary : c.primary),
                    ),
                  ),
                ),
              ),
            Transform.translate(offset: Offset(_dx.value, 0), child: child),
          ]);
        },
        child: widget.child,
      ),
    );
  }
}

/// Whether [quote] is taken from [words]: the same, or their start when a
/// long quote was cut short with an ellipsis.
bool quotes(String quote, String words) =>
    words == quote || (quote.endsWith('…') && words.startsWith(quote.substring(0, quote.length - 1)));
