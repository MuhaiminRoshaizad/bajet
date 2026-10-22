import 'package:bajet/core/theme/app_theme.dart';
import 'package:bajet/core/widgets/done_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<ScaffoldMessengerState> pumpPage(WidgetTester tester) async {
  await tester.pumpWidget(MaterialApp(theme: AppTheme.light(), home: const Scaffold(body: SizedBox.expand())));
  return tester.state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger));
}

void main() {
  testWidgets('a bar with Undo still leaves by itself after five seconds', (tester) async {
    final messenger = await pumpPage(tester);
    var undone = false;
    showBar(messenger, 'Saved MacBook', undo: () => undone = true);
    await tester.pumpAndSettle();
    expect(find.text('Saved MacBook'), findsOneWidget);
    expect(find.text('Undo'), findsOneWidget);

    await tester.pump(barDuration - const Duration(milliseconds: 100));
    expect(find.text('Saved MacBook'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
    expect(find.text('Saved MacBook'), findsNothing);
    expect(undone, isFalse);
  });

  testWidgets('a newer bar replaces the one showing at once, and Undo runs once tapped', (tester) async {
    final messenger = await pumpPage(tester);
    var undone = 0;
    showBar(messenger, 'Logged Coffee RM6.50');
    await tester.pumpAndSettle();
    showBar(messenger, 'Logged Bus RM2.00', undo: () => undone++);
    await tester.pumpAndSettle();
    expect(find.text('Logged Coffee RM6.50'), findsNothing);
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(undone, 1);
  });

  testWidgets('another choice can stand in for Undo', (tester) async {
    final messenger = await pumpPage(tester);
    var used = false;
    showBar(messenger, 'bajety pairs well with Sees Everything', action: ('Use it', () => used = true));
    await tester.pumpAndSettle();
    expect(find.text('Undo'), findsNothing);
    await tester.tap(find.text('Use it'));
    expect(used, isTrue);
  });
}
