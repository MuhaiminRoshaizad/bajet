import 'package:bajet/features/accounts/presentation/hold_swell.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late List<String> ticks;
  var taps = 0;

  setUp(() {
    ticks = [];
    taps = 0;
  });

  Future<void> pump(WidgetTester tester) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'HapticFeedback.vibrate') ticks.add(call.arguments as String);
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
    await tester.pumpWidget(MaterialApp(
      home: Center(
        child: HoldSwell(onTap: () => taps++, child: const SizedBox(key: ValueKey('card'), width: 200, height: 100)),
      ),
    ));
  }

  double scale(WidgetTester tester) => tester
      .widget<Transform>(find.ancestor(of: find.byKey(const ValueKey('card')), matching: find.byType(Transform)).first)
      .transform
      .getMaxScaleOnAxis();

  testWidgets('a quick tap opens, with no swell and no tick', (tester) async {
    await pump(tester);
    await tester.tap(find.byKey(const ValueKey('card')));
    await tester.pumpAndSettle();
    expect(taps, 1);
    expect(ticks, isEmpty);
  });

  testWidgets('pressed, the card swells with a light tick and a firmer one if held, and a hold is not a tap', (tester) async {
    await pump(tester);
    final press = await tester.startGesture(tester.getCenter(find.byKey(const ValueKey('card'))));
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pump(const Duration(milliseconds: 300));
    expect(ticks, ['HapticFeedbackType.lightImpact']);
    expect(scale(tester), greaterThan(1.04));

    await tester.pump(const Duration(milliseconds: 300));
    expect(ticks, ['HapticFeedbackType.lightImpact', 'HapticFeedbackType.mediumImpact']);

    await press.up();
    await tester.pumpAndSettle();
    expect(taps, 0);
    expect(scale(tester), closeTo(1, 0.001));
  });

  testWidgets('a slow tap, let go after the swell but before the firmer tick, still opens', (tester) async {
    await pump(tester);
    final press = await tester.startGesture(tester.getCenter(find.byKey(const ValueKey('card'))));
    await tester.pump(const Duration(milliseconds: 250));
    await press.up();
    await tester.pumpAndSettle();
    expect(taps, 1);
  });

  testWidgets('moving the finger springs the card back with no firmer tick', (tester) async {
    await pump(tester);
    final press = await tester.startGesture(tester.getCenter(find.byKey(const ValueKey('card'))));
    await tester.pump(const Duration(milliseconds: 200));
    await press.moveBy(const Offset(0, 40));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 600));
    expect(ticks, ['HapticFeedbackType.lightImpact']);
    expect(scale(tester), closeTo(1, 0.001));
    await press.up();
  });
}
