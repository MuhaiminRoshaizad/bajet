import 'dart:io';
import 'dart:ui' as ui;

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../domain/photo_colours.dart';

/// Reads a photo from the camera or the gallery small, takes its colours in
/// memory, then deletes the picker's copy.
class DevicePhotoColours implements PhotoColours {
  DevicePhotoColours([ImagePicker? picker]) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<List<int>?> pick(PhotoSource source) async {
    final picked = await _picker.pickImage(
      source: source == PhotoSource.camera ? ImageSource.camera : ImageSource.gallery,
      // Colours need no detail; a small image is quicker and holds no
      // readable card number.
      maxWidth: 160,
      maxHeight: 160,
      requestFullMetadata: false,
    );
    if (picked == null) return null;
    try {
      final codec = await ui.instantiateImageCodec(await picked.readAsBytes(), targetWidth: 48);
      final image = (await codec.getNextFrame()).image;
      final rgba = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      image.dispose();
      return rgba == null ? const [] : commonColours(rgba.buffer.asUint8List());
    } finally {
      // The picker leaves a scaled copy in the app's cache, which goes now.
      // Only a file inside that cache is ever deleted, so the owner's own
      // photo can never be.
      final cache = (await getTemporaryDirectory()).absolute.path;
      final copy = File(picked.path).absolute;
      if (copy.path.startsWith(cache) && await copy.exists()) await copy.delete();
    }
  }
}
