import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quick_actions/quick_actions.dart';

import '../domain/launch_link.dart';

/// The part of the phone's home screen bajet reaches: the launcher
/// shortcuts. Behind this interface so the app can be tested without a
/// launcher.
abstract interface class HomeSurface {
  /// Links opened from a shortcut, including the one that started the app,
  /// if any.
  Stream<LaunchLink> get launches;

  Future<void> setShortcuts(List<(int, String)> favourites);
}

class PlatformHomeSurface implements HomeSurface {
  PlatformHomeSurface() {
    _quickActions.initialize((type) {
      final link = LaunchLink.parse(Uri.tryParse(type));
      if (link != null) _links.add(link);
    });
  }

  final _quickActions = const QuickActions();
  final _links = StreamController<LaunchLink>.broadcast();

  @override
  Stream<LaunchLink> get launches => _links.stream;

  @override
  Future<void> setShortcuts(List<(int, String)> favourites) => _quickActions.setShortcutItems([
        // The link is the shortcut's type, so the logger is opened by the
        // same parser whichever shortcut was pressed.
        ShortcutItem(type: const LaunchLink.log().toUri().toString(), localizedTitle: 'Log a spend', icon: 'ic_shortcut_log'),
        for (final (id, label) in favourites.take(3))
          ShortcutItem(type: LaunchLink.log(favouriteId: id).toUri().toString(), localizedTitle: 'Log $label', icon: 'ic_shortcut_log'),
      ]);

}

final homeSurfaceProvider = Provider<HomeSurface>((ref) => PlatformHomeSurface());
