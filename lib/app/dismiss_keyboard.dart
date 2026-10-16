import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

/// Tapping anywhere outside the field being typed in puts the keyboard
/// away, on every screen and sheet. On a phone Flutter otherwise keeps the
/// field focused; it only does this on desktop. A drag that starts outside
/// the field, such as a scroll, leaves the keyboard up.
class DismissKeyboardOnTap {
  /// Where the finger went down outside the field, until it lifts.
  Offset? _down;

  late final actions = <Type, Action<Intent>>{
    EditableTextTapOutsideIntent: CallbackAction<EditableTextTapOutsideIntent>(
      onInvoke: (intent) => _down = intent.pointerDownEvent.position,
    ),
    EditableTextTapUpOutsideIntent: CallbackAction<EditableTextTapUpOutsideIntent>(
      onInvoke: (intent) {
        final down = _down;
        _down = null;
        if (down != null && (intent.pointerUpEvent.position - down).distance <= kTouchSlop) intent.focusNode.unfocus();
        return null;
      },
    ),
  };
}
