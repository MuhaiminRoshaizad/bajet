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
          title: 'This chat',
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

final card = find.byKey(const ValueKey('spring-menu-card'));

/// The card's drawn outline, which grows while its layout stays put.
Rect outline(WidgetTester tester) {
  final shape = tester.widget<PhysicalShape>(card);
  return shape.clipper.getClip(tester.getSize(card)).getBounds();
}

void main() {
  testWidgets('the button opens into the menu, passing its size before it settles', (tester) async {
    await pumpMenu(tester);
    final button = tester.getRect(find.byType(IconButton));
    await tester.tap(find.byTooltip('More'));
    await tester.pump();
    final full = tester.getSize(card);
    expect(outline(tester).size.width, closeTo(button.width, 1), reason: 'it starts as the button');
    expect(tester.getTopRight(card), button.topRight, reason: 'over the button, corners lined up');
    var most = 0.0;
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      if (outline(tester).width > most) most = outline(tester).width;
    }
    await tester.pumpAndSettle();
    expect(most, greaterThan(full.width * 1.02));
    expect(outline(tester).size, full);
    expect(find.text('THIS CHAT'), findsOneWidget);
    expect(find.byType(Divider), findsOneWidget, reason: 'delete sits below a line');
  });

  testWidgets('a choice is passed on and closes the menu; a tap outside folds it back into the button', (tester) async {
    final picked = await pumpMenu(tester);
    await tester.tap(find.byTooltip('More'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete chat'));
    await tester.pumpAndSettle();
    expect(picked, ['delete']);
    expect(find.text('Pin chat'), findsNothing);

    await tester.tap(find.byTooltip('More'));
    await tester.pumpAndSettle();
    final full = tester.getSize(card).width;
    await tester.tapAt(const Offset(20, 500));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    expect(outline(tester).width, lessThan(full), reason: 'it shrinks without passing its size first');
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
    expect(outline(tester).size, tester.getSize(card));
  });
}
