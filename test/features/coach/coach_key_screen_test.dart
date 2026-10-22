import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/app_harness.dart';

Future<void> openCoachSettings(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Settings'));
  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(find.text('Add your key'), 200);
  await tester.drag(find.byType(ListView).last, const Offset(0, -200));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Add your key'));
  await tester.pumpAndSettle();
}

Finder keyField() => find.widgetWithText(TextFormField, 'Anthropic API key');

void main() {
  testWidgets('a key is checked, saved to secure storage and never shown again', (tester) async {
    final world = await pumpApp(tester);
    await openCoachSettings(tester);

    await tester.enterText(keyField(), 'not-a-key');
    await tester.tap(find.text('Save the key'));
    await tester.pumpAndSettle();
    expect(find.text('That is not an Anthropic key. They start with sk-ant-'), findsOneWidget);
    expect(world.coachKeys.key, isNull);

    await tester.enterText(keyField(), 'sk-ant-test-0123456789abcdefghij');
    await tester.tap(find.text('Save the key'));
    await tester.pumpAndSettle();
    expect(world.coachKeys.key, 'sk-ant-test-0123456789abcdefghij');
    expect(find.text('A key is saved'), findsOneWidget);
    expect(find.text('sk-ant-test-0123456789abcdefghij'), findsNothing);
  });

  testWidgets('removing the key asks first', (tester) async {
    final world = await pumpApp(tester, seed: (w) => w.coachKeys.key = 'sk-ant-test-0123456789abcdefghij');
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Key saved'), 200);
    await tester.drag(find.byType(ListView).last, const Offset(0, -200));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Key saved'));
    await tester.pumpAndSettle();

    // The key field has a Scrollable of its own, so name the list's.
    final list = find.descendant(of: find.byType(ListView).last, matching: find.byType(Scrollable)).first;
    await tester.scrollUntilVisible(find.text('Remove the key'), 200, scrollable: list);
    // Built is not on screen: bring it fully into view before tapping.
    await tester.ensureVisible(find.text('Remove the key'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove the key'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Keep it'));
    await tester.pumpAndSettle();
    expect(world.coachKeys.key, isNotNull);

    await tester.tap(find.text('Remove the key'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();
    expect(world.coachKeys.key, isNull);
    expect(find.text('Key removed. The coach is off until a key is added.'), findsOneWidget);
  });
}
