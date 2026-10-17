import 'dart:convert';

import 'package:bajet/core/database/database_provider.dart';
import 'package:bajet/core/sharing/file_sharer.dart';
import 'package:bajet/core/theme/app_theme.dart';
import 'package:bajet/features/backup/domain/backup_repository.dart';
import 'package:bajet/features/backup/presentation/backup_files.dart';
import 'package:bajet/features/backup/presentation/backup_screen.dart';
import 'package:bajet/features/backup/presentation/restore_flow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/recording_sharer.dart';

class FakeFiles implements BackupFiles {
  String? toPick;

  @override
  Future<String?> pick() async => toPick;
}

class FakeBackups implements BackupRepository {
  Map<String, Object?>? restored;

  @override
  Future<Map<String, Object?>> export() async => {'app': 'bajet', 'format': backupFormatVersion, 'entries': []};

  @override
  Future<void> restore(Map<String, Object?> backup) async {
    if (backup['app'] != 'bajet') throw const BackupFormatException('This file is not a bajet backup.');
    restored = backup;
  }
}

/// The share sheet of the latest pumpBackup.
late RecordingSharer sharer;

Future<(FakeFiles, FakeBackups)> pumpBackup(WidgetTester tester) async {
  final files = FakeFiles();
  final backups = FakeBackups();
  sharer = RecordingSharer();
  await tester.pumpWidget(ProviderScope(
    overrides: [
      todayProvider.overrideWithValue(DateTime.utc(2026, 7, 1)),
      backupFilesProvider.overrideWithValue(files),
      fileSharerProvider.overrideWithValue(sharer),
      backupRepositoryProvider.overrideWithValue(backups),
    ],
    child: MaterialApp(theme: AppTheme.light(), home: const BackupScreen()),
  ));
  return (files, backups);
}

void main() {
  testWidgets('a backup can be shared as a dated JSON file', (tester) async {
    await pumpBackup(tester);
    await tester.tap(find.text('Share a backup file'));
    await tester.pumpAndSettle();
    expect(sharer.fileName, 'bajet-backup-2026-07-01.json');
    expect(jsonDecode(sharer.fileText!), {'app': 'bajet', 'format': backupFormatVersion, 'entries': []});
  });

  testWidgets('a backup can be saved straight to a folder, and says so', (tester) async {
    await pumpBackup(tester);
    await tester.tap(find.text('Save a backup file'));
    await tester.pumpAndSettle();
    expect(sharer.savedName, 'bajet-backup-2026-07-01.json');
    expect(jsonDecode(sharer.savedText!), {'app': 'bajet', 'format': backupFormatVersion, 'entries': []});
    expect(find.text('Saved bajet-backup-2026-07-01.json'), findsOneWidget);
  });

  testWidgets('cancelling the save leaves nothing behind', (tester) async {
    await pumpBackup(tester);
    sharer.saves = false;
    await tester.tap(find.text('Save a backup file'));
    await tester.pumpAndSettle();
    expect(sharer.savedName, isNull);
    expect(find.textContaining('Saved'), findsNothing);
  });

  testWidgets('restoring asks before replacing anything', (tester) async {
    final (files, backups) = await pumpBackup(tester);
    files.toPick = jsonEncode({'app': 'bajet', 'format': 1, 'entries': [{}, {}]});
    await tester.tap(find.text('Restore from a backup file'));
    await tester.pumpAndSettle();
    expect(find.textContaining('The backup holds 2 entries.'), findsOneWidget);

    await tester.tap(find.text('Keep what is here'));
    await tester.pumpAndSettle();
    expect(backups.restored, isNull);

    await tester.tap(find.text('Restore from a backup file'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Replace'));
    await tester.pumpAndSettle();
    expect(backups.restored, isNotNull);
    expect(find.text('Backup restored'), findsOneWidget);
  });

  testWidgets('a file that is not JSON is refused before anything happens', (tester) async {
    final (files, backups) = await pumpBackup(tester);
    files.toPick = 'not json at all';
    await tester.tap(find.text('Restore from a backup file'));
    await tester.pumpAndSettle();
    expect(find.text('That file is not a bajet backup.'), findsOneWidget);
    expect(find.text('Replace everything on this phone?'), findsNothing);
    expect(backups.restored, isNull);
  });

  testWidgets('a backup whose entries are not a list still opens the question, for restore to judge', (tester) async {
    final (files, _) = await pumpBackup(tester);
    files.toPick = jsonEncode({'app': 'bajet', 'format': 1, 'entries': 'oops'});
    await tester.tap(find.text('Restore from a backup file'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.textContaining('The backup holds 0 entries.'), findsOneWidget);
  });

  testWidgets('cancelling the picker changes nothing', (tester) async {
    final (_, backups) = await pumpBackup(tester);
    await tester.tap(find.text('Restore from a backup file'));
    await tester.pumpAndSettle();
    expect(find.text('Replace everything on this phone?'), findsNothing);
    expect(backups.restored, isNull);
  });
}
