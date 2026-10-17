import 'package:flutter/widgets.dart';

enum ReceiptSource { camera, gallery }

/// Receipt images kept on the phone, each known to an entry only by its file
/// name. Behind this interface so screens can be tested without the camera,
/// the gallery or the file system.
abstract interface class ReceiptStore {
  /// Lets the user take or pick a photo, keeps a compressed copy, and
  /// returns its file name; null if they cancelled.
  Future<String?> pick(ReceiptSource source);

  /// The image for display.
  Future<ImageProvider> image(String name);

  /// Deletes every kept image not named in [names], such as those of
  /// deleted entries or of a log that was never saved.
  Future<void> keepOnly(Set<String> names);
}
