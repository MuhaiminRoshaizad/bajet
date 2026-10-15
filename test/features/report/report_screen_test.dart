import 'dart:convert';

import 'package:bajet/core/sharing/file_sharer.dart';
import 'package:bajet/features/ledger/domain/ledger_models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/app_harness.dart';

class RecordingSharer implements FileSharer {
  String? text;
  String? fileName;
  String? fileText;

  @override
  Future<void> shareFile(List<int> bytes, String fileName, String mimeType) async {
    this.fileName = fileName;
    fileText = utf8.decode(bytes, allowMalformed: true);
  }

  @override
  Future<void> shareText(String text, {String? subject}) async => this.text = text;
}

Future<RecordingSharer> openReport(WidgetTester tester) async {
  final sharer = RecordingSharer();
  await pumpApp(
    tester,
    seed: (w) => w.add(EntryDraft(day: testToday, isIncome: false, amount: 800, categoryKey: 'food', label: 'Lunch')),
    overrides: (_) => [fileSharerProvider.overrideWithValue(sharer)],
  );
  await tester.tap(find.byTooltip('Settings'));
  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(find.text('Share a report'), 200);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Share a report'));
  await tester.pumpAndSettle();
  return sharer;
}

void main() {
  // The opening date is today, so every period starts there.
  testWidgets('the text report is previewed and shared as text', (tester) async {
    final sharer = await openReport(tester);
    expect(find.textContaining('bajet report, 01/07/2026 to 01/07/2026'), findsOneWidget);

    await tester.tap(find.text('Share'));
    await tester.pumpAndSettle();
    expect(sharer.text, contains('- Food: RM8.00'));
  });

  testWidgets('CSV shares every entry in the period as a dated file', (tester) async {
    final sharer = await openReport(tester);
    await tester.tap(find.text('CSV'));
    await tester.pumpAndSettle();
    expect(find.text('1 entry from 01/07/2026 to 01/07/2026.'), findsOneWidget);

    await tester.tap(find.text('Share CSV'));
    await tester.pumpAndSettle();
    expect(sharer.fileName, 'bajet-report-2026-07-01-to-2026-07-01.csv');
    expect(sharer.fileText, contains('2026-07-01,expense,Food,Lunch,,8.00'));
  });
}
