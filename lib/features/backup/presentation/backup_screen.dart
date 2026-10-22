import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../../core/sharing/file_sharer.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/done_bar.dart';
import '../../../core/widgets/soft.dart';
import 'restore_flow.dart';

class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  bool _busy = false;

  /// Writes the backup file and hands it to [send]: the share sheet, or
  /// the "Save to" screen.
  Future<void> _export(Future<void> Function(FileSharer sharer, List<int> bytes, String name) send) async {
    setState(() => _busy = true);
    try {
      final backup = await ref.read(backupRepositoryProvider).export();
      final today = ref.read(todayProvider);
      final name = 'bajet-backup-${today.toIso8601String().substring(0, 10)}.json';
      await send(ref.read(fileSharerProvider), utf8.encode(const JsonEncoder.withIndent('  ').convert(backup)), name);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _share(FileSharer sharer, List<int> bytes, String name) => sharer.shareFile(bytes, name, 'application/json');

  Future<void> _save(FileSharer sharer, List<int> bytes, String name) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (!await sharer.saveFile(bytes, name, 'application/json')) return;
      showBar(messenger, 'Saved $name');
    } on PlatformException {
      showBar(messenger, 'Could not save the file. Share it instead.');
    }
  }

  Future<void> _restore() async {
    setState(() => _busy = true);
    try {
      await pickAndRestore(context, ref, replacing: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final canSave = ref.watch(fileSharerProvider).canSave;
    return Scaffold(
      appBar: AppBar(title: const Text('Backup')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.l),
        children: [
          SoftWell(
            padding: const EdgeInsets.all(AppSpacing.l + 2),
            radius: AppRadii.card,
            child: Text(
              'Everything bajet knows lives only on this phone. When backup is on in Android\'s settings, Android copies it to your '
              'Google account about once a day. A backup file is a copy you keep yourself.',
              style: TextStyle(color: c.ink, height: 1.45),
            ),
          ),
          const SizedBox(height: AppSpacing.l),
          // Saving is the main way out where it exists; sharing stays for
          // sending the file to Drive or a chat.
          if (canSave) ...[
            FilledButton.icon(
              onPressed: _busy ? null : () => _export(_save),
              icon: const Icon(Icons.download_rounded),
              label: const Text('Save a backup file'),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
            ),
            const SizedBox(height: AppSpacing.m),
            OutlinedButton.icon(
              onPressed: _busy ? null : () => _export(_share),
              icon: const Icon(Icons.ios_share_rounded),
              label: const Text('Share a backup file'),
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(56)),
            ),
          ] else
            FilledButton.icon(
              onPressed: _busy ? null : () => _export(_share),
              icon: const Icon(Icons.ios_share_rounded),
              label: const Text('Share a backup file'),
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
