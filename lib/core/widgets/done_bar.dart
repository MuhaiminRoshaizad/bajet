import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../theme/app_colors.dart';

/// How long a bar stays before it slides away by itself.
const barDuration = Duration(seconds: 5);

const _rise = Duration(milliseconds: 450);
const _fall = Duration(milliseconds: 220);

/// Says at the foot of the page what was just done, or why it could not
/// be, in the past tense and naming the thing: "Saved MacBook". It springs
/// up, a thin line under it runs down over [barDuration], then it slides
/// away; a swipe down sends it at once, and a newer bar replaces it rather
/// than queueing. [undo] adds Undo; [action] offers some other choice
/// instead, named by its label.
void showBar(ScaffoldMessengerState messenger, String message, {VoidCallback? undo, (String, VoidCallback)? action}) {
  final (label, onPressed) = action ?? ('Undo', undo);
  final clock = _BarClock();
  messenger
    // Flutter would let the old bar finish leaving first; this one takes
    // its place at once instead.
    ..clearSnackBars()
    ..removeCurrentSnackBar();
  // Every page's Scaffold draws its own copy of a bar, so the copies keep
  // time on one clock: a page opened halfway carries on from there. Flutter's
  // own snackbar stays still and clear, so the bar's is the only movement.
  clock.controller = messenger.showSnackBar(
    SnackBar(
      content: _Bar(message: message, label: label, onPressed: onPressed, clock: clock),
      backgroundColor: Colors.transparent,
      elevation: 0,
      padding: EdgeInsets.zero,
      persist: true,
      shape: const RoundedRectangleBorder(),
    ),
    snackBarAnimationStyle: AnimationStyle.noAnimation,
  );
}

/// One bar's time, shared by every copy of it and read off the frame clock,
/// so all copies stand at the same point.
class _BarClock {
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? controller;
  Duration? _shownAt, _leftAt;
  var leaving = false;
  var _gone = false;

  /// Where the bar is at frame time [now]: how far up (0 to 1, past 1 as it
  /// springs), how much of its time is left, and whether it is on its way out.
  ({double up, double left, bool falling}) at(Duration now, {required bool waits, required bool still}) {
    final t = now - (_shownAt ??= now);
    if (!waits && t >= barDuration) leaving = true;
    final rising = still ? 1.0 : Curves.easeOutBack.transform(_share(t, _rise));
    final left = waits ? 1.0 : 1 - _share(t, barDuration);
    if (!leaving) return (up: rising, left: left, falling: false);
    final f = still ? 1.0 : _share(now - (_leftAt ??= now), _fall);
    if (f >= 1 && !_gone) {
      _gone = true;
      // After the frame: closing changes the messenger, which a build may not.
      SchedulerBinding.instance.addPostFrameCallback((_) => controller?.close());
    }
    return (up: rising * (1 - Curves.easeIn.transform(f)), left: left, falling: true);
  }

  static double _share(Duration t, Duration of) => (t.inMicroseconds / of.inMicroseconds).clamp(0.0, 1.0);
}

class _Bar extends StatefulWidget {
  const _Bar({required this.message, required this.label, required this.onPressed, required this.clock});

  final String message;
  final String label;
  final VoidCallback? onPressed;
  final _BarClock clock;

  @override
  State<_Bar> createState() => _BarState();
}

class _BarState extends State<_Bar> with SingleTickerProviderStateMixin {
  // A frame every tick while showing; the clock says where everything is.
  late final Ticker _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((_) => setState(() {}))..start();
  }

  void _choose() {
    widget.onPressed?.call();
    widget.clock.leaving = true;
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final style = Theme.of(context).snackBarTheme;
    // With TalkBack on, a bar with a choice waits to be dismissed, as
    // Flutter's own does, so it is not gone before it is read and reached.
    final waits = MediaQuery.accessibleNavigationOf(context) && widget.onPressed != null;
    final m = widget.clock.at(SchedulerBinding.instance.currentFrameTimeStamp, waits: waits, still: MediaQuery.disableAnimationsOf(context));
    return Opacity(
      opacity: m.up.clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset(0, 28 * (1 - m.up)),
        child: IgnorePointer(
          ignoring: m.falling,
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
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: m.left,
                      child: Container(
                        height: 2,
                        decoration: BoxDecoration(color: style.actionTextColor?.withValues(alpha: 0.45), borderRadius: BorderRadius.circular(1)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
