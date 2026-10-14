import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Moving backup files on and off the phone. The platform pickers sit behind
/// this so the screen can be tested without them.
abstract interface class BackupFiles {
  /// Offers [contents] as a file named [fileName] through the share sheet,
  /// where the owner can save it to Drive, Files or a chat.
  Future<void> share(String contents, String fileName);

  /// Lets the owner pick a backup file and returns its text, or null if they
  /// cancelled.
  Future<String?> pick();
}

class PlatformBackupFiles implements BackupFiles {
  const PlatformBackupFiles();

  static const _json = XTypeGroup(label: 'bajet backup', extensions: ['json'], mimeTypes: ['application/json']);

  @override
  Future<void> share(String contents, String fileName) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(contents);
    await SharePlus.instance.share(ShareParams(files: [XFile(file.path, mimeType: 'application/json')], subject: fileName));
  }

  @override
  Future<String?> pick() async {
    final file = await openFile(acceptedTypeGroups: [_json]);
    return file?.readAsString();
  }
}

final backupFilesProvider = Provider<BackupFiles>((ref) => const PlatformBackupFiles());
