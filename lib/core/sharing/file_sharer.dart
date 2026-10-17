import 'dart:io';

import 'package:flutter/services.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../platform/outside_app.dart';

/// Hands a file or a piece of text to the system share sheet, where the
/// user can send it to a chat or another app, or saves a file straight into
/// a folder they pick. Behind this interface so screens can be tested
/// without the platform screens.
abstract interface class FileSharer {
  Future<void> shareFile(List<int> bytes, String fileName, String mimeType);
  Future<void> shareText(String text, {String? subject});

  /// Whether [saveFile] works here. Android only for now; on iPhone the
  /// share sheet's own Save to Files does the job.
  bool get canSave;

  /// Opens the system's "Save to" screen with [fileName] filled in and
  /// writes the file where the user picks. False if they cancelled.
  Future<bool> saveFile(List<int> bytes, String fileName, String mimeType);
}

class PlatformFileSharer implements FileSharer {
  const PlatformFileSharer();

  @override
  Future<void> shareFile(List<int> bytes, String fileName, String mimeType) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes);
    await OutsideApp.run(() => SharePlus.instance.share(ShareParams(files: [XFile(file.path, mimeType: mimeType)], subject: fileName)));
  }

  @override
  Future<void> shareText(String text, {String? subject}) => OutsideApp.run(() => SharePlus.instance.share(ShareParams(text: text, subject: subject)));

  static const _files = MethodChannel('my.minned.bajet/files');

  @override
  bool get canSave => Platform.isAndroid;

  @override
  Future<bool> saveFile(List<int> bytes, String fileName, String mimeType) async {
    final saved = await OutsideApp.run(() => _files.invokeMethod<bool>('save', {'name': fileName, 'mime': mimeType, 'bytes': Uint8List.fromList(bytes)}));
    return saved ?? false;
  }
}

final fileSharerProvider = Provider<FileSharer>((ref) => const PlatformFileSharer());
