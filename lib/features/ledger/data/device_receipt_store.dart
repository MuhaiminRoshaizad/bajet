import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../domain/receipt_store.dart';

/// Receipts in a `receipts` folder inside the app's own documents, which no
/// other app can read and which Android Auto Backup includes.
class DeviceReceiptStore implements ReceiptStore {
  DeviceReceiptStore([ImagePicker? picker]) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  Future<Directory> _folder() async {
    final dir = Directory('${(await getApplicationDocumentsDirectory()).path}/receipts');
    return dir.create(recursive: true);
  }

  @override
  Future<String?> pick(ReceiptSource source) async {
    // Big enough to read a receipt's small print, small enough that a year
    // of them stays well inside Auto Backup's 25 MB.
    final picked = await _picker.pickImage(
      source: source == ReceiptSource.camera ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 75,
      requestFullMetadata: false,
    );
    if (picked == null) return null;
    final dot = picked.name.lastIndexOf('.');
    final name = '${DateTime.now().microsecondsSinceEpoch}${dot < 0 ? '.jpg' : picked.name.substring(dot)}';
    await picked.saveTo('${(await _folder()).path}/$name');
    return name;
  }

  @override
  Future<ImageProvider> image(String name) async => FileImage(File('${(await _folder()).path}/$name'));

  @override
  Future<void> keepOnly(Set<String> names) async {
    await for (final f in (await _folder()).list()) {
      if (f is File && !names.contains(f.uri.pathSegments.last)) await f.delete();
    }
  }
}
