import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/money/money.dart';
import '../../ledger/presentation/ledger_providers.dart';
import '../../plan/presentation/plan_providers.dart';
import '../data/home_surface.dart';
import '../domain/launch_link.dart';

/// The latest link opened from the home screen, held until the app shell is
/// ready to act on it, so a link that started the app is not lost.
class PendingLaunchController extends Notifier<LaunchLink?> {
  @override
  LaunchLink? build() {
    final sub = ref.watch(homeSurfaceProvider).launches.listen((link) => state = link);
    ref.onDispose(sub.cancel);
    return null;
  }

  void consume() => state = null;
}

final pendingLaunchProvider = NotifierProvider<PendingLaunchController, LaunchLink?>(PendingLaunchController.new);

/// Keeps the launcher shortcuts and the widget in step with favourites and
/// the week. Watched for the app's lifetime; it does its work as a side
/// effect each time an input changes.
final homeSurfaceSyncProvider = Provider<void>((ref) {
  final favourites = ref.watch(favouritesProvider).value;
  final spent = ref.watch(weekSpentProvider);
  final cap = ref.watch(settingsProvider).value?.weeklyCap;
  if (favourites == null || spent == null || cap == null) return;
  final surface = ref.watch(homeSurfaceProvider);
  final named = [for (final f in favourites) (f.id, f.label)];
  final left = cap - spent;
  unawaited(surface.setShortcuts(named));
  unawaited(surface.updateWidget(WidgetSnapshot(
    weekLine: left >= 0 ? '${Money.format(left)} left this week' : '${Money.format(-left)} over this week',
    favourites: named.take(2).toList(),
  )));
});
