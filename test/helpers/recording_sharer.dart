import 'dart:convert';

import 'package:bajet/core/sharing/file_sharer.dart';

/// Stands in for the share sheet and the "Save to" screen, keeping what was
/// handed to them.
class RecordingSharer implements FileSharer {
  String? text;
  String? fileName;
  String? fileText;
  String? savedName;
  String? savedText;

  /// What the "Save to" screen answers: false as if the owner cancelled.
  bool saves = true;

  @override
  Future<void> shareFile(List<int> bytes, String fileName, String mimeType) async {
    this.fileName = fileName;
    fileText = utf8.decode(bytes, allowMalformed: true);
  }

  @override
  Future<void> shareText(String text, {String? subject}) async => this.text = text;

  @override
  bool get canSave => true;

  @override
  Future<bool> saveFile(List<int> bytes, String fileName, String mimeType) async {
    if (!saves) return false;
    savedName = fileName;
    savedText = utf8.decode(bytes, allowMalformed: true);
    return true;
  }
}
