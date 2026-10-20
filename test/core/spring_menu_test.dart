import 'package:bajet/core/theme/app_theme.dart';
import 'package:bajet/core/widgets/spring_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<List<String>> pumpMenu(WidgetTester tester) async {
  final picked = <String>[];
  await tester.pumpWidget(MaterialApp(
    theme: AppTheme.light(),
    home: Scaffold(
      appBar: AppBar(actions: [
        SpringMenuButton<String>(
          items: const [
            SpringMenuItem(value: 'pin', icon: Icons.push_pin_outlined, label: 'Pin chat'),
            SpringMenuItem(value: 'delete', icon: Icons.delete_outline_rounded, label: 'Delete chat', destructive: true),
          ],
          onSelected: picked.add,
        ),
      ]),
    ),
  ));
  return picked;
}

double menuScale(WidgetTester tester) => tester.widget<ScaleTransition>(find.ancestor(of: find.text('Pin chat'), matching: find.byType(ScaleTransition)).first).scale.value;

void main() {
  testWidgets('the menu grows out of its corner, passing its size before it settles', (tester) async {
    await pumpMenu(tester);
    await tester.tap(find.byTooltip('More'));
    var most = 0.0;
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      if (menuScale(tester) > most) most = menuScale(tester);
    }
    await tester.pumpAndSettle();
    expect(most, greaterThan(1.02));
    expect(menuScale(tester), 1);
    // Below the button, right edges lined up.
    expect(tester.getTopRight(find.text('Pin chat')).dx, lessThan(tester.getTopRight(find.byTooltip('More')).dx));
  });

  testWidgets('a choice is passed on and closes the menu; a tap outside just closes it', (tester) async {
    final picked = await pumpMenu(tester);
    await tester.tap(find.byTooltip('More'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete chat'));
    await tester.pumpAndSettle();
    expect(picked, ['delete']);
    expect(find.text('Pin chat'), findsNothing);

    await tester.tap(find.byTooltip('More'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(20, 500));
    await tester.pumpAndSettle();
    expect(picked, ['delete']);
    expect(find.text('Pin chat'), findsNothing);
  });

  testWidgets('with animations off the menu simply appears', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await pumpMenu(tester);
    await tester.tap(find.byTooltip('More'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    expect(find.ancestor(of: find.text('Pin chat'), matching: find.byType(ScaleTransition)), findsNothing);
  });
}
