import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../domain/photo_colours.dart';

/// Picks a card's colour from a photo of it: the photo full screen with a
/// card-shaped frame to line the card up in, three colours from inside the
/// frame to choose from, and a tap or drag anywhere for an exact colour,
/// shown in a magnifier. Pops with the colour chosen; the photo goes with
/// the page.
Future<int?> showPhotoMatch(BuildContext context, PhotoSample photo) =>
    Navigator.of(context).push<int>(MaterialPageRoute(fullscreenDialog: true, builder: (_) => PhotoMatchScreen(photo: photo)));

class PhotoMatchScreen extends StatefulWidget {
  const PhotoMatchScreen({super.key, required this.photo});

  final PhotoSample photo;

  @override
  State<PhotoMatchScreen> createState() => _PhotoMatchScreenState();
}

class _PhotoMatchScreenState extends State<PhotoMatchScreen> {
  ui.Image? _image;
  late final List<int> _suggested = commonColours(widget.photo.framed, count: 3);
  late int? _colour = _suggested.firstOrNull;

  /// Where the finger is, as fractions of the photo, while it is down.
  Offset? _touch;

  @override
  void initState() {
    super.initState();
    final p = widget.photo;
    ui.decodeImageFromPixels(p.rgba, p.width, p.height, ui.PixelFormat.rgba8888, (image) {
      if (mounted) {
        setState(() => _image = image);
      } else {
        image.dispose();
      }
    });
  }

  @override
  void dispose() {
    _image?.dispose();
    super.dispose();
  }

  void _sample(Offset local, Size size) {
    final at = Offset((local.dx / size.width).clamp(0.0, 1.0), (local.dy / size.height).clamp(0.0, 1.0));
    final colour = widget.photo.colourAt(at.dx, at.dy);
    if (colour != _colour) HapticFeedback.selectionClick();
    setState(() {
      _touch = at;
      _colour = colour;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final p = widget.photo;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Match the colour'),
      ),
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.l, 0, AppSpacing.l, AppSpacing.m),
            child: Text(
              'Line the card up in the frame, or tap anywhere on it for an exact colour.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.75)),
            ),
          ),
          Expanded(
            child: Center(
              child: AspectRatio(
                key: const ValueKey('photo'),
                aspectRatio: p.width / p.height,
                child: LayoutBuilder(
                  builder: (context, box) => GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onPanDown: (d) => _sample(d.localPosition, box.biggest),
                    onPanUpdate: (d) => _sample(d.localPosition, box.biggest),
                    onPanEnd: (_) => setState(() => _touch = null),
                    onPanCancel: () => setState(() => _touch = null),
                    child: Stack(clipBehavior: Clip.none, children: [
                      Positioned.fill(child: _image == null ? const SizedBox.shrink() : RawImage(image: _image, fit: BoxFit.fill)),
                      Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: _FramePainter(p.frame)))),
                      if (_touch case final t? when _colour != null)
                        Positioned(
                          left: t.dx * box.maxWidth - 32,
                          top: t.dy * box.maxHeight - 96,
                          child: IgnorePointer(child: _Loupe(colour: Color(_colour!))),
                        ),
                    ]),
                  ),
                ),
              ),
            ),
          ),
          Container(
            color: c.background,
            padding: const EdgeInsets.fromLTRB(AppSpacing.l, AppSpacing.l, AppSpacing.l, AppSpacing.l),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
              Text('From inside the frame', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.muted)),
              const SizedBox(height: AppSpacing.s),
              Row(children: [
                for (final (i, s) in _suggested.indexed)
                  _Choice(
                    name: 'Colour ${i + 1} from your photo',
                    colour: Color(s),
                    selected: _colour == s,
                    onTap: () => setState(() => _colour = s),
                  ),
                if (_suggested.isEmpty) Text('Tap the photo to pick a colour.', style: TextStyle(color: c.muted)),
                const Spacer(),
                if (_colour != null) ...[
                  Text('Chosen', style: TextStyle(color: c.muted, fontSize: 13)),
                  const SizedBox(width: AppSpacing.s),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(color: Color(_colour!), borderRadius: BorderRadius.circular(10), border: Border.all(color: c.line)),
                  ),
                ],
              ]),
              const SizedBox(height: AppSpacing.l),
              FilledButton(
                onPressed: _colour == null ? null : () => Navigator.of(context).pop(_colour),
                child: const Text('Use this colour'),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

/// Darkens the photo outside the frame and outlines the frame, dashed.
class _FramePainter extends CustomPainter {
  const _FramePainter(this.frame);

  final ({double left, double top, double width, double height}) frame;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(frame.left * size.width, frame.top * size.height, frame.width * size.width, frame.height * size.height);
    final card = RRect.fromRectAndRadius(rect, Radius.circular(rect.height * 0.08));
    canvas.drawPath(
      Path.combine(PathOperation.difference, Path()..addRect(Offset.zero & size), Path()..addRRect(card)),
      Paint()..color = const Color(0x66000000),
    );
    final dash = Paint()
      ..color = const Color(0xD9FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (final metric in (Path()..addRRect(card)).computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 12) {
        canvas.drawPath(metric.extractPath(d, d + 7), dash);
      }
    }
  }

  @override
  bool shouldRepaint(_FramePainter old) => old.frame != frame;
}

/// The colour under the finger, held above it so the finger never hides it.
class _Loupe extends StatelessWidget {
  const _Loupe({required this.colour});

  final Color colour;

  @override
  Widget build(BuildContext context) => Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: colour,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: const [BoxShadow(color: Color(0x80000000), blurRadius: 12, offset: Offset(0, 4))],
        ),
      );
}

class _Choice extends StatelessWidget {
  const _Choice({required this.name, required this.colour, required this.selected, required this.onTap});

  final String name;
  final Color colour;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      selected: selected,
      label: name,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        radius: 26,
        child: SizedBox.square(
          dimension: 52,
          child: Center(
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: colour,
                shape: BoxShape.circle,
                border: Border.all(color: selected ? c.primary : c.line, width: selected ? 3 : 1),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
