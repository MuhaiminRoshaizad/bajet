import 'dart:math' as math;
import 'dart:typed_data';

enum PhotoSource { camera, gallery }

/// Takes a photo of the user's own card, for its colour. The photo is held
/// in memory only, small, while a colour is picked from it; it is never
/// written anywhere the app keeps, so no card number sits in the app, its
/// backups or an export.
abstract interface class PhotoColours {
  /// The photo, at most [PhotoSample.longSide] pixels on its long side; null
  /// if cancelled.
  Future<PhotoSample?> pick(PhotoSource source);
}

/// A small photo as RGBA pixels, row by row.
class PhotoSample {
  const PhotoSample({required this.width, required this.height, required this.rgba});

  /// Large enough to tap a colour precisely, small enough to keep no detail.
  static const longSide = 480;

  final int width;
  final int height;
  final Uint8List rgba;

  /// The card-shaped frame the card is lined up in, as a fraction of the
  /// photo: centred, 80% of its width, 1.9 times as wide as tall, smaller
  /// if the photo is too short for that.
  ({double left, double top, double width, double height}) get frame {
    var w = 0.8;
    var h = w * width / height / 1.9;
    if (h > 0.9) (w, h) = (w * 0.9 / h, 0.9);
    return (left: (1 - w) / 2, top: (1 - h) / 2, width: w, height: h);
  }

  /// The pixels inside [frame].
  Uint8List get framed {
    final f = frame;
    final x0 = (f.left * width).round(), x1 = ((f.left + f.width) * width).round();
    final y0 = (f.top * height).round(), y1 = ((f.top + f.height) * height).round();
    final out = BytesBuilder(copy: false);
    for (var y = y0; y < y1; y++) {
      out.add(Uint8List.sublistView(rgba, (y * width + x0) * 4, (y * width + x1) * 4));
    }
    return out.takeBytes();
  }

  /// The colour at a point given as fractions of the photo, averaged over
  /// the pixels around it so one speck of noise does not decide it.
  int colourAt(double fx, double fy) {
    final cx = (fx.clamp(0.0, 1.0) * (width - 1)).round(), cy = (fy.clamp(0.0, 1.0) * (height - 1)).round();
    var r = 0, g = 0, b = 0, n = 0;
    for (var y = math.max(0, cy - 2); y <= math.min(height - 1, cy + 2); y++) {
      for (var x = math.max(0, cx - 2); x <= math.min(width - 1, cx + 2); x++) {
        final i = (y * width + x) * 4;
        r += rgba[i];
        g += rgba[i + 1];
        b += rgba[i + 2];
        n++;
      }
    }
    return 0xFF000000 | (r ~/ n) << 16 | (g ~/ n) << 8 | b ~/ n;
  }
}

/// The most common distinct colours in RGBA [pixels], up to [count]. Pixels
/// are grouped by their top four bits per channel and each group averaged;
/// a group too close to one already chosen is skipped, so the colours are
/// genuinely different. Mostly see-through pixels are ignored.
List<int> commonColours(Uint8List pixels, {int count = 5}) {
  final groups = <int, List<int>>{};
  for (var i = 0; i + 3 < pixels.length; i += 4) {
    if (pixels[i + 3] < 128) continue;
    final r = pixels[i], g = pixels[i + 1], b = pixels[i + 2];
    final sums = groups.putIfAbsent((r >> 4) << 8 | (g >> 4) << 4 | b >> 4, () => [0, 0, 0, 0]);
    sums[0]++;
    sums[1] += r;
    sums[2] += g;
    sums[3] += b;
  }
  final picked = <(int, int, int)>[];
  for (final s in groups.values.toList()..sort((a, b) => b[0].compareTo(a[0]))) {
    final c = (s[1] ~/ s[0], s[2] ~/ s[0], s[3] ~/ s[0]);
    if (picked.every((p) => _distance(p, c) > 56)) picked.add(c);
    if (picked.length == count) break;
  }
  return [for (final (r, g, b) in picked) 0xFF000000 | r << 16 | g << 8 | b];
}

double _distance((int, int, int) a, (int, int, int) b) =>
    math.sqrt(math.pow(a.$1 - b.$1, 2) + math.pow(a.$2 - b.$2, 2) + math.pow(a.$3 - b.$3, 2));
