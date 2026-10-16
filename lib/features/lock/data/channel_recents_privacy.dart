import 'package:flutter/services.dart';

import '../domain/app_lock.dart';

/// Talks to MainActivity, which uses Android's own setting for this. It
/// exists on Android 13 and later only; older phones keep the picture.
class ChannelRecentsPrivacy implements RecentsPrivacy {
  const ChannelRecentsPrivacy();

  static const _channel = MethodChannel('my.minned.bajet/privacy');

  @override
  Future<void> hideFromRecents(bool hidden) => _channel.invokeMethod<void>('hideFromRecents', hidden);
}
