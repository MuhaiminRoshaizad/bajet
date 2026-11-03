import 'package:bajet/features/coach/domain/coach_client.dart';
import 'package:bajet/features/coach/domain/coach_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_repositories.dart';
import 'coach_screen_test.dart' show openCoach;

const _reply = '**Phone plan:** −RM45.00, was due 28/10 and not logged as paid yet.\n\n- Internet: −RM129.00';

/// A chat holding one question and the coach's reply to it.
Future<FakeWorld> openChat(WidgetTester tester) => openCoach(tester, seed: (w) {
      w.coachChat.restore([
        chatWith([
          CoachMessage(fromUser: true, text: 'what is left this month', sentAt: DateTime(2026, 7, 1, 9), id: 1),
          CoachMessage(fromUser: false, text: _reply, sentAt: DateTime(2026, 7, 1, 9, 1), face: CoachFace.aina, id: 2),
        ], face: CoachFace.aina),
      ]);
    });

Future<void> hold(WidgetTester tester, int message) async {
  await tester.longPress(find.byKey(ValueKey(('hold', message))));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets("holding the coach's reply offers Copy and Select text; Copy takes the words without the marks", (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') copied = (call.arguments as Map)['text'] as String;
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
    await openChat(tester);

    await hold(tester, 1);
    expect(find.byKey(const ValueKey('message-menu')), findsOneWidget);
    expect([for (final l in ['Copy', 'Select text']) find.text(l).evaluate().length], [1, 1]);

    await tester.tap(find.text('Copy'));
    // Settling would run the bar's five seconds out, so only part way.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(copied, 'Phone plan: −RM45.00, was due 28/10 and not logged as paid yet.\n• Internet: −RM129.00');
    expect(find.text('Message copied'), findsOneWidget);
    expect(find.byKey(const ValueKey('message-menu')), findsNothing);
  });

  testWidgets('Select text opens the message on its own, selectable', (tester) async {
    await openChat(tester);
    await hold(tester, 1);
    await tester.tap(find.text('Select text'));
    await tester.pumpAndSettle();
    final text = tester.widget<SelectableText>(find.byKey(const ValueKey('select-text')));
    expect(text.data, startsWith('Phone plan: −RM45.00'));
  });
}
