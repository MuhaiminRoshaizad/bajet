import 'dart:convert';

import 'package:bajet/features/backup/domain/backup_repository.dart';
import 'package:bajet/features/backup/presentation/backup_files.dart';
import 'package:bajet/features/backup/presentation/restore_flow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/fake_repositories.dart';

class _PickedFile implements BackupFiles {
  @override
  Future<String?> pick() async => jsonEncode({'app': 'bajet', 'format': 1, 'entries': []});
}

/// Stands in for the real repository by saving the settings a backup would
/// carry.
class _RestoreInto implements BackupRepository {
  _RestoreInto(this.world);

  final FakeWorld world;

  @override
  Future<Map<String, Object?>> export() async => {};

  @override
  Future<void> restore(Map<String, Object?> backup) => world.saveSettings(demoSettings);
}

Finder field(String label) => find.widgetWithText(TextFormField, label);

/// Adds cash holding [sen] on the first step.
Future<void> addCash(WidgetTester tester, String sen) async {
  await tester.tap(find.text('Cash'));
  await tester.pumpAndSettle();
  await tester.enterText(field('How much is in it now'), sen);
  await tester.ensureVisible(find.text('Add account'));
  await tester.tap(find.text('Add account'));
  await tester.pumpAndSettle();
}

/// Adds an account, then gives the weekly allowance, landing on the goal.
Future<void> fillMoneyStep(WidgetTester tester) async {
  await addCash(tester, '250000');
  await tester.tap(find.text('Continue'));
  await tester.pumpAndSettle();
  await tester.enterText(field('Weekly allowance'), '5000');
  await tester.tap(find.text('Continue'));
  await tester.pumpAndSettle();
}

/// Past the accounts, on the allowance.
Future<void> toWeekStep(WidgetTester tester) async {
  await addCash(tester, '250000');
  await tester.tap(find.text('Continue'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a new install opens on setup, not Today', (tester) async {
    await pumpApp(tester, setUpDone: false);
    expect(find.text('Where do you keep your money?'), findsOneWidget);
    expect(find.byKey(const ValueKey('tab-Today')), findsNothing);
  });

  testWidgets('setup cannot go on until there is somewhere money is kept', (tester) async {
    final world = await pumpApp(tester, setUpDone: false);
    expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Add an account to continue')).onPressed, isNull);

    await addCash(tester, '8450');
    expect(world.accounts.single.balance, 8450);
    expect(find.text('RM84.50'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Continue'), findsOneWidget);
  });

  testWidgets('required fields are flagged only when Continue is pressed', (tester) async {
    await pumpApp(tester, setUpDone: false);
    await toWeekStep(tester);
    expect(find.text('Enter how much you allow each week'), findsNothing);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Enter how much you allow each week'), findsOneWidget);
  });

  testWidgets('an error clears as soon as the value becomes valid', (tester) async {
    await pumpApp(tester, setUpDone: false);
    await toWeekStep(tester);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    await tester.enterText(field('Weekly allowance'), '5000');
    await tester.pumpAndSettle();
    expect(find.text('Enter how much you allow each week'), findsNothing);
    expect(find.text('50.00'), findsOneWidget);
  });

  testWidgets('skipping the goal saves settings and lands on Today', (tester) async {
    final world = await pumpApp(tester, setUpDone: false);
    await fillMoneyStep(tester);

    expect(find.text('Your first goal'), findsOneWidget);
    await tester.tap(find.text('Skip for now'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('tab-Today')), findsOneWidget);
    final s = world.settings!;
    expect((s.weeklyCap, s.buffer, s.openingDate), (5000, 0, testToday));
    expect(world.accounts.single.balance, 250000);
    expect(world.goals, isEmpty);
  });

  testWidgets('the weekly allowance is spread over the rhythm, so days are not planned at RM0', (tester) async {
    final world = await pumpApp(tester, setUpDone: false);
    await fillMoneyStep(tester);
    await tester.tap(find.text('Skip for now'));
    await tester.pumpAndSettle();

    final rules = await world.watchRules().first;
    // RM50 a week: RM7.15 on Monday and Tuesday, RM7.14 on the other five.
    expect([for (final r in rules) r.plannedSpend], [715, 715, 714, 714, 714, 714, 714]);
  });

  testWidgets('a half-filled goal cannot be skipped by accident', (tester) async {
    await pumpApp(tester, setUpDone: false);
    await fillMoneyStep(tester);

    await tester.enterText(field('Goal'), 'Laptop');
    await tester.pumpAndSettle();
    expect(find.text('Clear the goal to skip it'), findsOneWidget);

    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();
    expect(find.text('Enter the price'), findsOneWidget);
    expect(find.text('Pick the day you plan to buy it'), findsOneWidget);
  });

  testWidgets('RM sits beside an amount, never in front of the hint', (tester) async {
    await pumpApp(tester, setUpDone: false);
    await toWeekStep(tester);
    InputDecoration decoration() =>
        tester.widget<TextField>(find.descendant(of: field('Weekly allowance'), matching: find.byType(TextField))).decoration!;
    expect((decoration().prefixText, decoration().hintText), (null, 'e.g. 50.00'));

    await tester.enterText(field('Weekly allowance'), '5000');
    await tester.pump();
    expect(decoration().prefixText, 'RM');
  });

  testWidgets('the buy day calendar opens with no day chosen for the owner', (tester) async {
    await pumpApp(tester, setUpDone: false);
    await fillMoneyStep(tester);

    await tester.tap(find.text('Pick a buy day'));
    await tester.pumpAndSettle();
    // The header reads like "Fri, Jan 15" once a day is chosen, and is empty until then.
    expect(find.text('Buy day'), findsOneWidget);
    expect(find.textContaining(RegExp(r'^\w{3}, \w{3} \d+$')), findsNothing);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Pick a buy day'), findsOneWidget);
  });

  testWidgets('a new phone can start from a backup instead of setup', (tester) async {
    final world = await pumpApp(
      tester,
      setUpDone: false,
      overrides: (world) => [
        backupFilesProvider.overrideWithValue(_PickedFile()),
        backupRepositoryProvider.overrideWithValue(_RestoreInto(world)),
      ],
    );
    await tester.tap(find.text('Restore from a backup file instead'));
    await tester.pumpAndSettle();
    expect(find.text('Restore this backup?'), findsOneWidget);

    await tester.tap(find.text('Restore'));
    await tester.pumpAndSettle();
    expect(world.settings, isNotNull);
    expect(find.byKey(const ValueKey('tab-Today')), findsOneWidget);
    expect(find.text('Backup restored'), findsOneWidget);
  });
}
