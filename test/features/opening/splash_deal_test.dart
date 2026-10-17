// Android's splash animation is generated from the opening's timeline, so
// the deal Android plays and the hand-over bajet plays can never drift
// apart. After changing the timeline, regenerate it with
//   flutter test test/features/opening/splash_deal_test.dart --dart-define=UPDATE_SPLASH=true
// The wordmark's outlines in fixtures/wordmark_glyphs.json come from
// assets/fonts/Figtree-ExtraBold.ttf through fontTools' SVGPathPen, with
// each glyph's advance and the font's hhea ascender and descender. Letters
// are placed from those, not from TextPainter, whose widths and rounded line
// height differ slightly between Linux and Windows.
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:bajet/features/accounts/presentation/card_face.dart' show cardAspectRatio;
import 'package:bajet/features/opening/domain/opening_timeline.dart';
import 'package:bajet/features/opening/presentation/titanium_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _path = 'android/app/src/main/res/drawable-v31/splash_deal.xml';

/// Android draws the animated icon in a 288 dp square centred on the screen,
/// and keeps only a circle 192 dp across in view.
const _side = 288.0, _mid = _side / 2, _visible = 96.0;
const _frames = 60;

String _n(double v) {
  final s = v.toStringAsFixed(3);
  return s.contains('.') ? s.replaceFirst(RegExp(r'\.?0+$'), '') : s;
}

String _hex(Color c) => '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

String _rrect(Rect r, double radius) {
  final x = r.left, y = r.top, w = r.width, h = r.height, k = radius;
  return 'M${_n(x + k)},${_n(y)}h${_n(w - 2 * k)}a${_n(k)},${_n(k)} 0 0 1 ${_n(k)},${_n(k)}v${_n(h - 2 * k)}a${_n(k)},${_n(k)} 0 0 1 -${_n(k)},${_n(k)}'
      'h-${_n(w - 2 * k)}a${_n(k)},${_n(k)} 0 0 1 -${_n(k)},-${_n(k)}v-${_n(h - 2 * k)}a${_n(k)},${_n(k)} 0 0 1 ${_n(k)},-${_n(k)}z';
}

class _Anim {
  _Anim(this.target);

  final String target;
  final props = <String, List<double>>{};

  void add(String property, List<double> values) {
    // A property that never changes needs no animator.
    if (values.every((v) => (v - values.first).abs() < 1e-6)) return;
    props[property] = values;
  }

  String xml() {
    if (props.isEmpty) return '';
    final b = StringBuffer('    <target android:name="$target">\n        <aapt:attr name="android:animation">\n            <set android:ordering="together">\n');
    for (final MapEntry(key: p, value: v) in props.entries) {
      b.write('                <objectAnimator android:duration="${OpeningTimes.dealEnd.round()}" android:interpolator="@android:interpolator/linear">\n'
          '                    <propertyValuesHolder android:propertyName="$p" android:valueType="floatType">\n');
      for (var i = 0; i < v.length; i++) {
        b.write('                        <keyframe android:fraction="${_n(i / (v.length - 1))}" android:value="${_n(v[i])}" />\n');
      }
      b.write('                    </propertyValuesHolder>\n                </objectAnimator>\n');
    }
    return '$b            </set>\n        </aapt:attr>\n    </target>\n';
  }
}

Future<String> generate() async {
  final plan = OpeningPlan(const Size(_side, _side), const NoTarget());
  final times = [for (var i = 0; i <= _frames; i++) OpeningTimes.dealEnd * i / _frames];
  final vector = StringBuffer();
  final anims = <_Anim>[];

  // The three cards, back to front, drawn round the square's centre.
  const w = OpeningPlan.cardWidth, h = w / cardAspectRatio;
  final body = Rect.fromCenter(center: const Offset(_mid, _mid), width: w, height: h);
  final chip = TitaniumCard.chipAt(w).shift(body.topLeft);
  for (var i = 0; i < 3; i++) {
    final poses = [for (final t in times) plan.card(i, t)];
    final p0 = poses.first;
    vector.write('        <group android:name="card$i" android:pivotX="${_n(_mid)}" android:pivotY="${_n(_mid)}"'
        ' android:translateX="${_n(p0.centre.dx - _mid)}" android:translateY="${_n(p0.centre.dy - _mid)}"'
        ' android:rotation="${_n(p0.turn)}" android:scaleX="${_n(p0.width / w)}" android:scaleY="${_n(p0.width / w)}">\n'
        '            <path android:name="card${i}Body" android:fillColor="${_hex(titaniumShades[i])}" android:fillAlpha="${_n(p0.opacity)}" android:pathData="${_rrect(body, TitaniumCard.radiusAt(w))}" />\n');
    if (i == 2) {
      vector.write('            <path android:name="card${i}Chip" android:fillColor="${_hex(graphite)}" android:fillAlpha="${_n(.32 * p0.opacity)}" android:pathData="${_rrect(chip, 4 * w / 330)}" />\n');
    }
    vector.write('        </group>\n');
    anims.add(_Anim('card$i')
      ..add('translateX', [for (final p in poses) p.centre.dx - _mid])
      ..add('translateY', [for (final p in poses) p.centre.dy - _mid])
      ..add('rotation', [for (final p in poses) p.turn])
      ..add('scaleX', [for (final p in poses) p.width / w])
      ..add('scaleY', [for (final p in poses) p.width / w]));
    anims.add(_Anim('card${i}Body')..add('fillAlpha', [for (final p in poses) p.opacity]));
    if (i == 2) anims.add(_Anim('card${i}Chip')..add('fillAlpha', [for (final p in poses) .32 * p.opacity]));
  }

  // The wordmark: each letter laid out as bajet lays it out, rising from
  // behind its own line.
  final glyphs = jsonDecode(File('test/features/opening/fixtures/wordmark_glyphs.json').readAsStringSync()) as Map<String, dynamic>;
  final size = wordmarkStyle.fontSize!;
  final scale = size / (glyphs['unitsPerEm'] as num);
  final letters = 'bajet'.split('');
  // As Flutter lays out each letter at height 1: its advance plus the
  // letter spacing across, the font size high, the ascender's share of it
  // above the baseline.
  final widths = [for (final l in letters) ((glyphs['glyphs'] as Map)[l]['advance'] as num) * scale + wordmarkStyle.letterSpacing!];
  final ascender = glyphs['ascender'] as num, descender = glyphs['descender'] as num;
  final total = widths.fold(0.0, (s, w) => s + w + 1);
  var x = _mid - total / 2;
  final top = plan.wordTop;
  for (final (i, l) in letters.indexed) {
    final box = Rect.fromLTWH(x, top, widths[i] + 1, size);
    final baseline = top + size * ascender / (ascender - descender);
    final frames = [for (final t in times) plan.letter(i, t)];
    vector.write('        <group>\n'
        '            <clip-path android:pathData="M${_n(box.left)},${_n(box.top)}h${_n(box.width)}v${_n(box.height)}h-${_n(box.width)}z" />\n'
        '            <group android:name="letter$i" android:translateY="${_n(frames.first.drop * wordmarkStyle.fontSize!)}">\n'
        '                <group android:translateX="${_n(x + .5)}" android:translateY="${_n(baseline)}" android:scaleX="${_n(scale)}" android:scaleY="${_n(-scale)}">\n'
        '                    <path android:name="glyph$i" android:fillColor="${_hex(wordmarkStyle.color!)}" android:fillAlpha="${_n(frames.first.opacity)}" android:pathData="${(glyphs['glyphs'] as Map)[l]['d']}" />\n'
        '                </group>\n            </group>\n        </group>\n');
    anims.add(_Anim('letter$i')..add('translateY', [for (final f in frames) f.drop * wordmarkStyle.fontSize!]));
    anims.add(_Anim('glyph$i')..add('fillAlpha', [for (final f in frames) f.opacity]));
    x += widths[i] + 1;
  }

  // The titanium line under the word, drawing out from the middle.
  final lines = [for (final t in times) plan.lineAt(t)];
  final line = Rect.fromLTWH(_mid - OpeningPlan.lineWidth / 2, plan.lineTop, OpeningPlan.lineWidth, 2);
  vector.write('        <group android:name="line" android:pivotX="${_n(_mid)}" android:scaleX="${_n(lines.first)}">\n'
      '            <path android:name="lineBody" android:fillAlpha="${_n(lines.first)}" android:pathData="${_rrect(line, 1)}">\n'
      '                <aapt:attr name="android:fillColor">\n'
      '                    <gradient android:type="linear" android:startX="${_n(line.left)}" android:startY="0" android:endX="${_n(line.right)}" android:endY="0">\n'
      '                        <item android:offset="0" android:color="#00D8DBDF" />\n'
      '                        <item android:offset="0.3" android:color="#FFD8DBDF" />\n'
      '                        <item android:offset="0.7" android:color="#FFD8DBDF" />\n'
      '                        <item android:offset="1" android:color="#00D8DBDF" />\n'
      '                    </gradient>\n                </aapt:attr>\n            </path>\n        </group>\n');
  anims.add(_Anim('line')..add('scaleX', lines));
  anims.add(_Anim('lineBody')..add('fillAlpha', lines));

  return '<?xml version="1.0" encoding="utf-8"?>\n'
      '<!-- Generated by test/features/opening/splash_deal_test.dart from\n'
      '     lib/features/opening/domain/opening_timeline.dart. Do not edit by hand.\n'
      '     Android plays this on its splash screen the moment bajet is tapped:\n'
      '     one titanium card, then two, then three spring into the fan, and\n'
      '     "bajet" rises underneath. bajet takes over from its last frame. -->\n'
      '<animated-vector xmlns:android="http://schemas.android.com/apk/res/android"\n    xmlns:aapt="http://schemas.android.com/aapt">\n'
      '    <aapt:attr name="android:drawable">\n'
      '        <vector android:width="${_n(_side)}dp" android:height="${_n(_side)}dp" android:viewportWidth="${_n(_side)}" android:viewportHeight="${_n(_side)}">\n'
      '$vector'
      '        </vector>\n    </aapt:attr>\n'
      '${anims.map((a) => a.xml()).join()}'
      '</animated-vector>\n';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final figtree = FontLoader('Figtree')..addFont(rootBundle.load('assets/fonts/Figtree-ExtraBold.ttf'));
    await figtree.load();
  });

  test("Android's splash animation is the opening's timeline, up to the hand-over", () async {
    final xml = await generate();
    if (const bool.fromEnvironment('UPDATE_SPLASH')) File(_path).writeAsStringSync(xml);
    expect(File(_path).readAsStringSync().replaceAll('\r\n', '\n'), xml, reason: 'regenerate the splash animation, see the top of this file');
  });

  test('every card, even mid-bounce, the word and its line stay inside the circle Android shows', () {
    final plan = OpeningPlan(const Size(_side, _side), const NoTarget());
    const centre = Offset(_mid, _mid);
    var furthest = 0.0;
    for (var t = 0.0; t <= OpeningTimes.dealEnd; t += 2) {
      for (var i = 0; i < 3; i++) {
        final p = plan.card(i, t);
        if (p.opacity < .01) continue;
        final w = p.width, h = w / cardAspectRatio, a = p.turn * math.pi / 180;
        for (final (dx, dy) in [(-w / 2, -h / 2), (w / 2, -h / 2), (w / 2, h / 2), (-w / 2, h / 2)]) {
          final corner = p.centre + Offset(dx * math.cos(a) - dy * math.sin(a), dx * math.sin(a) + dy * math.cos(a));
          furthest = math.max(furthest, (corner - centre).distance);
        }
      }
    }
    final word = TextPainter(text: const TextSpan(text: 'bajet', style: wordmarkStyle), textDirection: TextDirection.ltr, textScaler: TextScaler.noScaling)..layout();
    furthest = math.max(furthest, Offset(word.width / 2 + 3, plan.wordTop + word.height - _mid).distance);
    furthest = math.max(furthest, Offset(OpeningPlan.lineWidth / 2, plan.lineTop + 2 - _mid).distance);
    expect(furthest, lessThan(_visible));
  });
}
