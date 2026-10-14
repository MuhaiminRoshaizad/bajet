import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:quick_actions/quick_actions.dart';

import '../domain/launch_link.dart';

/// The parts of the phone's home screen bajet reaches: launcher shortcuts and
/// the home-screen widget. Behind this interface so the app can be tested
/// without either.
abstract interface class HomeSurface {
  /// Links opened from a shortcut or the widget, including the one that
  /// started the app, if any.
  Stream<LaunchLink> get launches;

  Future<void> setShortcuts(List<(int, String)> favourites);
  Future<void> updateWidget(WidgetSnapshot snapshot);
}

class PlatformHomeSurface implements HomeSurface {
  PlatformHomeSurface() {
    _quickActions.initialize((type) {
      final link = LaunchLink.parse(Uri.tryParse(type));
      if (link != null) _links.add(link);
    });
    HomeWidget.initiallyLaunchedFromHomeWidget().then(_fromWidget);
    HomeWidget.widgetClicked.listen(_fromWidget);
  }

  /// Must match the provider class in android/app/src/main/kotlin.
  static const _androidWidget = 'BajetWidgetProvider';

  final _quickActions = const QuickActions();
  final _links = StreamController<LaunchLink>.broadcast();

  void _fromWidget(Uri? uri) {
    final link = LaunchLink.parse(uri);
    if (link != null) _links.add(link);
  }

  @override
  Stream<LaunchLink> get launches => _links.stream;

  @override
  Future<void> setShortcuts(List<(int, String)> favourites) => _quickActions.setShortcutItems([
        // The link is the shortcut's type, so one parser serves both surfaces.
        ShortcutItem(type: const LaunchLink.log().toUri().toString(), localizedTitle: 'Log a spend', icon: 'ic_shortcut_log'),
        for (final (id, label) in favourites.take(3))
          ShortcutItem(type: LaunchLink.log(favouriteId: id).toUri().toString(), localizedTitle: 'Log $label', icon: 'ic_shortcut_log'),
      ]);

  @override
  Future<void> updateWidget(WidgetSnapshot snapshot) async {
    await HomeWidget.saveWidgetData<String>('week_line', snapshot.weekLine);
    for (var i = 0; i < 2; i++) {
      final fav = i < snapshot.favourites.length ? snapshot.favourites[i] : null;
      await HomeWidget.saveWidgetData<String>('fav${i + 1}_label', fav?.$2);
      await HomeWidget.saveWidgetData<String>('fav${i + 1}_link', fav == null ? null : LaunchLink.log(favouriteId: fav.$1).toUri().toString());
    }
    await HomeWidget.updateWidget(androidName: _androidWidget);
  }
}

final homeSurfaceProvider = Provider<HomeSurface>((ref) => PlatformHomeSurface());
