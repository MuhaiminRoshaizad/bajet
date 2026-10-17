import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../data/drift_backup_repository.dart';
import '../domain/backup_repository.dart';
import 'backup_files.dart';

final backupRepositoryProvider = Provider<BackupRepository>((ref) => DriftBackupRepository(ref.watch(databaseProvider)));

/// Lets the user pick a backup file, confirms, and restores it. Used from
/// Settings and from first-run setup, so a new phone can start from a backup.
/// [replacing] is false on a fresh install, where there is nothing to lose.
Future<void> pickAndRestore(BuildContext context, WidgetRef ref, {required bool replacing}) async {
  final messenger = ScaffoldMessenger.of(context);
  void say(String message) => messenger
    ..clearSnackBars()
    ..showSnackBar(SnackBar(content: Text(message)));

  final text = await ref.read(backupFilesProvider).pick();
  if (text == null || !context.mounted) return;
  final Map<String, Object?> backup;
  try {
    backup = jsonDecode(text) as Map<String, Object?>;
  } on FormatException {
    say('That file is not a bajet backup.');
    return;
  } on TypeError {
    say('That file is not a bajet backup.');
    return;
  }
  // Read for the count only; restore checks the file as a whole.
  final entries = switch (backup['entries']) { final List<Object?> l => l.length, _ => 0 };
  final holds = 'The backup holds $entries ${entries == 1 ? 'entry' : 'entries'}.';
  final c = context.colors;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(replacing ? 'Replace everything on this phone?' : 'Restore this backup?'),
      content: Text(replacing ? '$holds Everything bajet has now, including entries made since, will be replaced by it.' : holds),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(replacing ? 'Keep what is here' : 'Cancel')),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: replacing ? FilledButton.styleFrom(backgroundColor: c.bad, foregroundColor: c.onBad) : null,
          child: Text(replacing ? 'Replace' : 'Restore'),
        ),
      ],
    ),
  );
  if (confirmed != true) return;
  try {
    await ref.read(backupRepositoryProvider).restore(backup);
    say('Backup restored');
  } on BackupFormatException catch (e) {
    say(e.message);
  }
}
