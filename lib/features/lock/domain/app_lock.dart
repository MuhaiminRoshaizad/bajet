/// How long bajet may sit in the background before it asks again.
enum LockGrace {
  immediately(Duration.zero, 'Straight away'),
  oneMinute(Duration(minutes: 1), '1 minute'),
  fiveMinutes(Duration(minutes: 5), '5 minutes');

  const LockGrace(this.duration, this.label);

  final Duration duration;
  final String label;
}

/// The owner's app lock choices. Off until the owner turns it on.
class LockSettings {
  const LockSettings({this.enabled = false, this.grace = LockGrace.oneMinute});

  final bool enabled;
  final LockGrace grace;

  LockSettings copyWith({bool? enabled, LockGrace? grace}) => LockSettings(enabled: enabled ?? this.enabled, grace: grace ?? this.grace);

  @override
  bool operator ==(Object other) => other is LockSettings && other.enabled == enabled && other.grace == grace;

  @override
  int get hashCode => Object.hash(enabled, grace);
}

abstract interface class LockSettingsStore {
  Future<LockSettings> read();
  Future<void> write(LockSettings settings);
}

/// How an attempt to prove it is the owner ended.
enum AuthOutcome {
  passed,

  /// Dismissed, or interrupted by the system; asking again is fine.
  cancelled,

  /// Too many wrong fingers; the phone's PIN still works.
  lockedOut,

  /// The phone has no fingerprint, face or screen lock left to check.
  unavailable,
  failed,
}

/// The phone's own fingerprint, face or screen lock. bajet keeps no PIN of
/// its own (docs/decisions.md 017).
abstract interface class DeviceAuth {
  /// Whether the phone has anything to check: an enrolled fingerprint or
  /// face, or a PIN, pattern or password.
  Future<bool> isAvailable();

  /// Shows the phone's prompt, headed [title], which always accepts the
  /// phone's PIN too. [reason] says what passing it does.
  Future<AuthOutcome> authenticate({required String title, required String reason});
}

/// Whether Android may keep a picture of bajet for the app switcher. While
/// the lock is on it may not, so the switcher shows a blank card instead of
/// the balance. Screenshots the owner takes still work.
abstract interface class RecentsPrivacy {
  Future<void> hideFromRecents(bool hidden);
}
