import 'dart:async';

import 'package:flutter/services.dart';

/// The hand-over from Android's splash screen to bajet's own first frames
/// (docs/decisions.md 018). MainActivity keeps the splash up until both its
/// animation has finished and bajet asks for it to go.
abstract interface class SplashHandOver {
  /// Completes once Android's splash animation has finished: true when
  /// Android played the deal (Android 12 and later), false when there was
  /// no animated splash and bajet must play the deal itself.
  Future<bool> ready();

  /// Takes Android's splash away, now that bajet draws the same picture.
  Future<void> remove();
}

class ChannelSplashHandOver implements SplashHandOver {
  const ChannelSplashHandOver();

  static const _channel = MethodChannel('my.minned.bajet/launch');

  @override
  Future<bool> ready() async {
    try {
      // Never wait for ever: without an answer, bajet plays the deal itself.
      return await _channel.invokeMethod<bool>('splashReady').timeout(const Duration(seconds: 3), onTimeout: () => false) ?? false;
    } on MissingPluginException {
      return false;
    }
  }

  @override
  Future<void> remove() async {
    try {
      await _channel.invokeMethod<void>('removeSplash');
    } on MissingPluginException {
      return;
    }
  }
}
