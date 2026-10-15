import 'dart:math' as math;
import 'dart:typed_data';

enum PhotoSource { camera, gallery }

/// Takes colours from a photo of the owner's own card, for its look. Only
/// colours come back; the photo is never kept, so no card number ever sits
/// in the app, its backups or an export.
abstract interface class PhotoColours {
  /// Up to five colours as ARGB, most common first; null if cancelled.
  Future<List<int>?> pick(PhotoSource source);
}

/// The most common distinct colours in RGBA [pixels], up to [count]. Pixels
/// are grouped by their top four bits per channel and each group averaged;
/// a group too close to one already chosen is skipped, so the five are
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
