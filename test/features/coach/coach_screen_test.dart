import 'package:bajet/features/ledger/domain/ledger_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/app_harness.dart';

void main() {
  testWidgets('shows the week summary and copies it', (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') copied = (call.arguments as Map)['text'] as String;
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));

    await pumpApp(tester, seed: (w) => w.add(EntryDraft(day: testToday, isIncome: false, amount: 1200, categoryKey: 'food')));
    await tester.tap(find.byKey(const ValueKey('tab-Coach')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Balance: RM1,488.00'), findsOneWidget);
    await tester.tap(find.text('Copy summary'));
    await tester.pumpAndSettle();
    expect(copied, contains('Flexible spending this week: RM12.00 of RM50.00'));
    expect(find.text('Summary copied'), findsOneWidget);
  });
}
