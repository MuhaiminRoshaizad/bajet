import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../platform/outside_app.dart';

/// Hands a file or a piece of text to the system share sheet, where the
/// owner can save it to Drive or Files or send it to a chat. Behind this
/// interface so screens can be tested without the platform sheet.
abstract interface class FileSharer {
  Future<void> shareFile(List<int> bytes, String fileName, String mimeType);
  Future<void> shareText(String text, {String? subject});
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
}

final fileSharerProvider = Provider<FileSharer>((ref) => const PlatformFileSharer());
