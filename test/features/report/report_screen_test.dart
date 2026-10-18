
import 'package:bajet/core/sharing/file_sharer.dart';
import 'package:bajet/features/ledger/domain/ledger_models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/recording_sharer.dart';

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
  testWidgets('this week is previewed and shared as the check-in', (tester) async {
    final sharer = await openReport(tester);
    expect(find.textContaining('bajet · weekly check-in · Mon 29/06 – Sun 05/07/2026'), findsOneWidget);

    await tester.tap(find.text('Share'));
    await tester.pumpAndSettle();
    expect(sharer.text, contains('  Food RM8.00'));
  });

  testWidgets('a month is shared as the general report', (tester) async {
    final sharer = await openReport(tester);
    await tester.tap(find.text('Month'));
    await tester.pumpAndSettle();
    expect(find.textContaining('bajet report, 01/07/2026 to 01/07/2026'), findsOneWidget);

    await tester.tap(find.text('Share'));
    await tester.pumpAndSettle();
    expect(sharer.text, contains('- Food: RM8.00'));
  });

  testWidgets("this week's PDF is the check-in, with the app's own drawings", (tester) async {
    final sharer = await openReport(tester);
    await tester.tap(find.text('PDF'));
    await tester.pumpAndSettle();
    expect(find.text('The check-in on one page, then every entry, to keep or print'), findsOneWidget);

    // Drawing the icon and the coach takes real time, not the test's clock.
    await tester.runAsync(() async {
      await tester.tap(find.text('Share PDF'));
      for (var n = 0; n < 50 && sharer.fileName == null; n++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        await tester.pump();
      }
    });
    expect(sharer.fileName, 'bajet-check-in-2026-07-01.pdf');
    expect(sharer.fileText, startsWith('%PDF-'));
  });

  testWidgets('CSV shares every entry in the period as a dated file', (tester) async {
    final sharer = await openReport(tester);
    await tester.tap(find.text('CSV'));
    await tester.pumpAndSettle();
    expect(find.text('1 entry from 01/07/2026 to 01/07/2026.'), findsOneWidget);

    await tester.tap(find.text('Share CSV'));
    await tester.pumpAndSettle();
    expect(sharer.fileName, 'bajet-report-2026-07-01-to-2026-07-01.csv');
    expect(sharer.fileText, contains('2026-07-01,expense,Main account,Food,Lunch,,8.00'));
  });

  testWidgets('a CSV can be saved straight to a folder; text has nothing to save', (tester) async {
    final sharer = await openReport(tester);
    expect(find.text('Save'), findsNothing);

    await tester.tap(find.text('CSV'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(sharer.savedName, 'bajet-report-2026-07-01-to-2026-07-01.csv');
    expect(sharer.savedText, contains('2026-07-01,expense,Main account,Food,Lunch,,8.00'));
    expect(find.text('Saved bajet-report-2026-07-01-to-2026-07-01.csv'), findsOneWidget);
  });
}
