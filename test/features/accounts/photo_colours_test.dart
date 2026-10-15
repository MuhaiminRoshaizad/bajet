import 'dart:typed_data';

import 'package:bajet/features/accounts/domain/photo_colours.dart';
import 'package:flutter_test/flutter_test.dart';

Uint8List pixels(List<(int r, int g, int b, int count)> runs) => Uint8List.fromList([
      for (final (r, g, b, n) in runs)
        for (var i = 0; i < n; i++) ...[r, g, b, 255],
    ]);

void main() {
  test('the most common colours come first, one for each truly different shade', () {
    final photo = pixels([(200, 16, 46, 60), (203, 18, 44, 20), (240, 240, 240, 15), (20, 20, 20, 5)]);
    // The two reds fall in one group and are averaged: (200, 16, 45).
    expect(commonColours(photo), [0xFFC8102D, 0xFFF0F0F0, 0xFF141414]);
  });

  test('stops at the number asked for, and ignores see-through pixels', () {
    final photo = Uint8List.fromList([...pixels([(0, 0, 255, 3), (255, 0, 0, 2), (0, 255, 0, 1)]), 9, 9, 9, 0]);
    expect(commonColours(photo, count: 2), [0xFF0000FF, 0xFFFF0000]);
    expect(commonColours(Uint8List(0)), isEmpty);
  });
}
