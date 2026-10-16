import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/platform/outside_app.dart';
import '../data/file_lock_settings_store.dart';
import '../data/local_device_auth.dart';
import '../domain/app_lock.dart';

final lockSettingsStoreProvider = Provider<LockSettingsStore>((ref) => FileLockSettingsStore());
final deviceAuthProvider = Provider<DeviceAuth>((ref) => LocalDeviceAuth());

/// The choices as read before the first frame, so a locked app never shows
/// the money before the lock screen. Overridden in main.
final initialLockSettingsProvider = Provider<LockSettings>((ref) => const LockSettings());

/// What the lock measures time away with. Overridden in tests.
final lockClockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

class LockSettingsController extends Notifier<LockSettings> {
  @override
  LockSettings build() => ref.watch(initialLockSettingsProvider);

  /// Turns the lock on only after the phone has checked it is the owner, so
  /// it can never be switched on in a way the owner cannot get past.
  Future<AuthOutcome> enable() async {
    final outcome = await ref.read(deviceAuthProvider).authenticate(title: 'Turn on App lock', reason: 'bajet will ask for this each time it opens.');
    if (outcome == AuthOutcome.passed) await _save(state.copyWith(enabled: true));
    return outcome;
  }

  Future<void> disable() => _save(state.copyWith(enabled: false));

  Future<void> setGrace(LockGrace grace) => _save(state.copyWith(grace: grace));

  Future<void> _save(LockSettings settings) async {
    state = settings;
    await ref.read(lockSettingsStoreProvider).write(settings);
  }
}

final lockSettingsProvider = NotifierProvider<LockSettingsController, LockSettings>(LockSettingsController.new);

/// Whether the lock screen is covering the app. Locked on a cold start when
/// the lock is on, and again on coming back after longer away than the
/// owner's grace. Time in a screen bajet opened itself does not count.
class AppLockController extends Notifier<bool> {
  DateTime? _awaySince;

  @override
  bool build() {
    final listener = AppLifecycleListener(onStateChange: _changed);
    ref.onDispose(listener.dispose);
    return ref.read(initialLockSettingsProvider).enabled;
  }

  void _changed(AppLifecycleState lifecycle) {
    final settings = ref.read(lockSettingsProvider);
    final now = ref.read(lockClockProvider);
    switch (lifecycle) {
      case AppLifecycleState.hidden || AppLifecycleState.paused:
        if (settings.enabled && !OutsideApp.isOpen) _awaySince ??= now();
      case AppLifecycleState.resumed:
        final since = _awaySince;
        _awaySince = null;
        if (settings.enabled && since != null && now().difference(since) >= settings.grace.duration) state = true;
      case AppLifecycleState.inactive || AppLifecycleState.detached:
        break;
    }
  }

  void unlock() => state = false;

  /// For a phone that no longer has anything to check: the lock turns off
  /// and the app opens, rather than locking the owner out of their own data.
  Future<void> turnOffAndOpen() async {
    await ref.read(lockSettingsProvider.notifier).disable();
    unlock();
  }
}

final appLockProvider = NotifierProvider<AppLockController, bool>(AppLockController.new);
