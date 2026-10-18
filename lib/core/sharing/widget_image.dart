import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Draws [child] off screen, [size] logical pixels across, at [pixelRatio]
/// pixels for each, and returns it as a PNG. It borrows [context]'s themes,
/// text direction and media query, so it looks as it would on screen. For
/// pictures in a PDF or an image to share, never shown in the app itself.
Future<Uint8List> widgetToPng(BuildContext context, Widget child, {required Size size, double pixelRatio = 3}) async {
  final boundary = RenderRepaintBoundary();
  final view = RenderView(
    view: View.of(context),
    configuration: ViewConfiguration(logicalConstraints: BoxConstraints.tight(size)),
    child: boundary,
  );
  final pipeline = PipelineOwner()..rootNode = view;
  view.prepareInitialFrame();
  final focus = FocusManager();
  final build = BuildOwner(focusManager: focus);
  final tree = InheritedTheme.captureAll(
    context,
    MediaQuery(
      data: MediaQuery.of(context).copyWith(size: size),
      child: Directionality(textDirection: Directionality.of(context), child: child),
    ),
  );
  final root = RenderObjectToWidgetAdapter<RenderBox>(container: boundary, child: tree).attachToRenderTree(build);
  build
    ..buildScope(root)
    ..finalizeTree();
  pipeline
    ..flushLayout()
    ..flushCompositingBits()
    ..flushPaint();
  final image = await boundary.toImage(pixelRatio: pixelRatio);
  try {
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    return png!.buffer.asUint8List();
  } finally {
    image.dispose();
    focus.dispose();
  }
}
