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

  test('the frame is centred, card-shaped, and its pixels are only those inside it', () {
    final photo = PhotoSample(width: 40, height: 30, rgba: Uint8List(40 * 30 * 4));
    final f = photo.frame;
    expect(f.left, closeTo(0.1, 1e-9));
    expect(f.width, closeTo(0.8, 1e-9));
    expect(f.width * 40 / (f.height * 30), closeTo(1.9, 1e-9));
    expect(f.top + f.height / 2, closeTo(0.5, 1e-9));
    // Rows 7 to 22 and columns 4 to 35.
    expect(photo.framed.length, 32 * 16 * 4);
  });

  test('a photo too short for the frame gets a smaller one that still fits', () {
    final f = PhotoSample(width: 100, height: 30, rgba: Uint8List(100 * 30 * 4)).frame;
    expect(f.height, closeTo(0.9, 1e-9));
    expect(f.width * 100 / (f.height * 30), closeTo(1.9, 1e-9));
  });

  test('a colour picked from the photo is the average of the pixels around the point', () {
    final rgba = Uint8List(10 * 10 * 4);
    for (var i = 0; i < 100; i++) {
      rgba.setAll(i * 4, i % 10 < 5 ? [200, 0, 0, 255] : [0, 0, 200, 255]);
    }
    final photo = PhotoSample(width: 10, height: 10, rgba: rgba);
    expect(photo.colourAt(0, 0), 0xFFC80000);
    expect(photo.colourAt(1, 1), 0xFF0000C8);
  });
}
