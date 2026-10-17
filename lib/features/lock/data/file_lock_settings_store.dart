import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../domain/app_lock.dart';

/// Two words in a file of the app's own, such as "on oneMinute": a device
/// preference like the theme, so it stays out of the database and out of
/// backup files.
class FileLockSettingsStore implements LockSettingsStore {
  Future<File> _file() async => File('${(await getApplicationSupportDirectory()).path}/app_lock');

  @override
  Future<LockSettings> read() async {
    try {
      return parse(await (await _file()).readAsString());
    } on FileSystemException {
      return const LockSettings();
    }
  }

  @override
  Future<void> write(LockSettings settings) async => (await _file()).writeAsString(format(settings));

  static String format(LockSettings s) => '${s.enabled ? 'on' : 'off'} ${s.grace.name}';

  /// Anything unreadable falls back to the lock being off, never to a lock
  /// the user cannot get past.
  static LockSettings parse(String text) {
    final words = text.trim().split(' ');
    return LockSettings(
      enabled: words.first == 'on',
      grace: LockGrace.values.firstWhere((g) => words.length > 1 && g.name == words[1], orElse: () => LockGrace.oneMinute),
    );
  }
}
