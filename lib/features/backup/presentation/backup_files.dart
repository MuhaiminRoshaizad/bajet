import 'package:file_selector/file_selector.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/platform/outside_app.dart';

/// Picking a backup file to restore. The platform picker sits behind this so
/// the screen can be tested without it; exporting goes through FileSharer.
abstract interface class BackupFiles {
  /// Lets the user pick a backup file and returns its text, or null if they
  /// cancelled.
  Future<String?> pick();
}

class PlatformBackupFiles implements BackupFiles {
  const PlatformBackupFiles();

  static const _json = XTypeGroup(label: 'bajet backup', extensions: ['json'], mimeTypes: ['application/json']);

  @override
  Future<String?> pick() async {
    final file = await OutsideApp.run(() => openFile(acceptedTypeGroups: [_json]));
    return file?.readAsString();
  }
}

final backupFilesProvider = Provider<BackupFiles>((ref) => const PlatformBackupFiles());
