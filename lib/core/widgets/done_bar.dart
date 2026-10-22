import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// How long a bar stays before it slides away by itself.
const barDuration = Duration(seconds: 5);

/// Says at the foot of the page what was just done, or why it could not
/// be, in the past tense and naming the thing: "Saved MacBook". It springs
/// up, a thin line under it runs down over [barDuration], then it slides
/// away; a swipe down sends it at once, and a newer bar replaces it rather
/// than queueing. [undo] adds Undo; [action] offers some other choice
/// instead, named by its label.
void showBar(ScaffoldMessengerState messenger, String message, {VoidCallback? undo, (String, VoidCallback)? action}) {
  final (label, onPressed) = action ?? ('Undo', undo);
  messenger
    // Flutter would let the old bar finish leaving first; this one takes
    // its place at once instead.
    ..clearSnackBars()
    ..removeCurrentSnackBar()
    // The bar times and moves itself (_Bar), so Flutter's own snackbar is
    // only a clear frame that stays until the bar takes itself away.
    ..showSnackBar(SnackBar(
      content: _Bar(message: message, label: label, onPressed: onPressed, messenger: messenger),
      backgroundColor: Colors.transparent,
      elevation: 0,
      padding: EdgeInsets.zero,
      persist: true,
      shape: const RoundedRectangleBorder(),
    ));
}

class _Bar extends StatefulWidget {
  const _Bar({required this.message, required this.label, required this.onPressed, required this.messenger});

  final String message;
  final String label;
  final VoidCallback? onPressed;
  final ScaffoldMessengerState messenger;

  @override
  State<_Bar> createState() => _BarState();
}

class _BarState extends State<_Bar> with TickerProviderStateMixin {
  /// 0 to 1 as it springs up; back to 0 as it slides away.
  late final _shown = AnimationController(vsync: this, duration: const Duration(milliseconds: 450), reverseDuration: const Duration(milliseconds: 220));

  /// Runs from full to empty over [barDuration], then the bar leaves.
  late final _left = AnimationController(vsync: this, duration: barDuration, value: 1);
  var _leaving = false;

  @override
  void initState() {
    super.initState();
    _left.addStatusListener((s) {
      if (s == AnimationStatus.dismissed) _leave();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still = MediaQuery.disableAnimationsOf(context);
    if (_shown.status == AnimationStatus.dismissed && !_leaving) still ? _shown.value = 1 : _shown.forward();
    // With TalkBack on, a bar with a choice waits to be dismissed, as
    // Flutter's own does, so it is not gone before it is read and reached.
    final reading = MediaQuery.accessibleNavigationOf(context) && widget.onPressed != null;
    if (!reading && !_left.isAnimating && !_leaving) _left.reverse(from: _left.value);
  }

  Future<void> _leave() async {
    if (_leaving) return;
    _leaving = true;
    if (!MediaQuery.disableAnimationsOf(context)) {
      try {
        await _shown.reverse().orCancel;
      } on TickerCanceled {
        // A newer bar took this one's place first.
        return;
      }
    }
    if (mounted) widget.messenger.removeCurrentSnackBar();
  }

  void _choose() {
    widget.onPressed?.call();
    _left.stop();
    _leave();
  }

  @override
  void dispose() {
    _shown.dispose();
    _left.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final style = Theme.of(context).snackBarTheme;
    return AnimatedBuilder(
      animation: _shown,
      builder: (context, child) {
        final t = _shown.status == AnimationStatus.reverse ? Curves.easeIn.transform(_shown.value) : Curves.easeOutBack.transform(_shown.value);
        return Opacity(
          opacity: _shown.value.clamp(0.0, 1.0),
          child: Transform.translate(offset: Offset(0, 28 * (1 - t)), child: child),
        );
      },
      child: Material(
        color: c.ink,
        shape: style.shape,
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(widget.message, style: style.contentTextStyle),
                    ),
                  ),
                  if (widget.onPressed != null)
                    TextButton(
                      onPressed: _choose,
                      style: TextButton.styleFrom(foregroundColor: style.actionTextColor, textStyle: const TextStyle(fontWeight: FontWeight.w700)),
                      child: Text(widget.label),
                    ),
                ],
              ),
            ),
            // The time left, draining from the right.
            Positioned(
              left: 16,
              right: 16,
              bottom: 4,
              child: AnimatedBuilder(
                animation: _left,
                builder: (context, _) => Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: _left.value,
                    child: Container(
                      height: 2,
                      decoration: BoxDecoration(color: style.actionTextColor?.withValues(alpha: 0.45), borderRadius: BorderRadius.circular(1)),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
