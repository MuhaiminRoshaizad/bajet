import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../ledger/presentation/ledger_providers.dart';
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

/// Keeps the launcher shortcuts in step with the favourites. Watched for the
/// app's lifetime; it does its work as a side effect each time they change.
final homeSurfaceSyncProvider = Provider<void>((ref) {
  final favourites = ref.watch(favouritesProvider).value;
  if (favourites == null) return;
  unawaited(ref.watch(homeSurfaceProvider).setShortcuts([for (final f in favourites) (f.id, f.label)]));
});
