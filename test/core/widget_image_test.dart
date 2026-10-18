import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:bajet/core/sharing/widget_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('draws a widget off screen as a PNG of its size times the pixel ratio, in the theme around it', (tester) async {
    late BuildContext context;
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0C5F96))),
      home: Builder(builder: (c) {
        context = c;
        return const SizedBox();
      }),
    ));
    final primary = Theme.of(context).colorScheme.primary;

    final pixels = await tester.runAsync(() async {
      // Takes its colour from the theme, which only reaches it if the theme
      // is carried over.
      final png = await widgetToPng(context, Builder(builder: (c) => ColoredBox(color: Theme.of(c).colorScheme.primary)), size: const Size(10, 6), pixelRatio: 2);
      final codec = await ui.instantiateImageCodec(png);
      final image = (await codec.getNextFrame()).image;
      final rgba = (await image.toByteData())!;
      return (image.width, image.height, rgba);
    });
    expect(tester.takeException(), isNull);
    final (width, height, ByteData rgba) = pixels!;
    expect((width, height), (20, 12));
    expect(Color.fromARGB(rgba.getUint8(3), rgba.getUint8(0), rgba.getUint8(1), rgba.getUint8(2)), primary);
  });
}
