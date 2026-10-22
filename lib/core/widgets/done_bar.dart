import 'package:flutter/material.dart';

/// How long a bar stays before it slides away by itself.
const barDuration = Duration(seconds: 5);

/// Says at the foot of the page what was just done, or why it could not
/// be, in the past tense and naming the thing: "Saved MacBook". It slides
/// away after [barDuration] or on a swipe down, and a newer bar replaces it
/// at once rather than queueing. [undo] adds Undo; [action] offers some
/// other choice instead, named by its label.
///
/// Flutter keeps a bar with an action up until it is tapped unless told
/// otherwise, hence `persist: false`.
void showBar(ScaffoldMessengerState messenger, String message, {VoidCallback? undo, (String, VoidCallback)? action}) {
  final (label, onPressed) = action ?? ('Undo', undo);
  messenger
    ..clearSnackBars()
    ..showSnackBar(SnackBar(
      content: Text(message),
      duration: barDuration,
      persist: false,
      action: onPressed == null ? null : SnackBarAction(label: label, onPressed: onPressed),
    ));
}
