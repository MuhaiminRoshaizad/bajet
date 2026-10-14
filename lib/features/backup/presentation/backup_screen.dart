import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../data/drift_backup_repository.dart';
import '../domain/backup_repository.dart';
import 'backup_files.dart';

final backupRepositoryProvider = Provider<BackupRepository>((ref) => DriftBackupRepository(ref.watch(databaseProvider)));

class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  bool _busy = false;

  void _say(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _export() async {
    setState(() => _busy = true);
    try {
      final backup = await ref.read(backupRepositoryProvider).export();
      final today = ref.read(todayProvider);
      final name = 'bajet-backup-${today.toIso8601String().substring(0, 10)}.json';
      await ref.read(backupFilesProvider).share(const JsonEncoder.withIndent('  ').convert(backup), name);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore() async {
    final text = await ref.read(backupFilesProvider).pick();
    if (text == null || !mounted) return;
    final Map<String, Object?> backup;
    try {
      backup = jsonDecode(text) as Map<String, Object?>;
    } on FormatException {
      _say('That file is not a bajet backup.');
      return;
    } on TypeError {
      _say('That file is not a bajet backup.');
      return;
    }
    final entries = (backup['entries'] as List<Object?>?)?.length ?? 0;
    final c = context.colors;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Replace everything on this phone?'),
        content: Text('The backup holds $entries ${entries == 1 ? 'entry' : 'entries'}. Everything bajet has now, including entries made since, will be replaced by it.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Keep what is here')),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: c.bad, foregroundColor: c.card),
            child: const Text('Replace'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _busy = true);
    try {
      await ref.read(backupRepositoryProvider).restore(backup);
      _say('Backup restored');
    } on BackupFormatException catch (e) {
      _say(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      appBar: AppBar(title: const Text('Backup'), backgroundColor: c.background),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.l),
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.l + 2),
            decoration: BoxDecoration(color: c.primarySoft, borderRadius: BorderRadius.circular(AppRadii.card)),
            child: Text(
              'Everything bajet knows lives only on this phone. When backup is on in Android\'s settings, Android copies it to your '
              'Google account about once a day. A backup file is a copy you keep yourself.',
              style: TextStyle(color: c.ink, height: 1.45),
            ),
          ),
          const SizedBox(height: AppSpacing.l),
          FilledButton.icon(
            onPressed: _busy ? null : _export,
            icon: const Icon(Icons.ios_share_rounded),
            label: const Text('Export a backup file'),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
          ),
          const SizedBox(height: AppSpacing.m),
          OutlinedButton.icon(
            onPressed: _busy ? null : _restore,
            icon: const Icon(Icons.restore_rounded),
            label: const Text('Restore from a backup file'),
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(56)),
          ),
        ],
      ),
    );
  }
}
