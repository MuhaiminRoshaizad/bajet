import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

/// Where the owner's light or dark choice is kept between launches.
abstract interface class ThemeModeStore {
  Future<ThemeMode> read();
  Future<void> write(ThemeMode mode);
}

/// One word in a file of the app's own: a device preference, not plan data,
/// so it stays out of the database and out of backup files.
class FileThemeModeStore implements ThemeModeStore {
  Future<File> _file() async => File('${(await getApplicationSupportDirectory()).path}/theme_mode');

  @override
  Future<ThemeMode> read() async {
    try {
      final name = (await (await _file()).readAsString()).trim();
      return ThemeMode.values.firstWhere((m) => m.name == name, orElse: () => ThemeMode.system);
    } on FileSystemException {
      return ThemeMode.system;
    }
  }

  @override
  Future<void> write(ThemeMode mode) async => (await _file()).writeAsString(mode.name);
}

final themeModeStoreProvider = Provider<ThemeModeStore>((ref) => FileThemeModeStore());

/// The choice as read before the first frame, so the app never opens in the
/// wrong theme and then switches. Overridden in main.
final initialThemeModeProvider = Provider<ThemeMode>((ref) => ThemeMode.system);

class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ref.watch(initialThemeModeProvider);

  Future<void> choose(ThemeMode mode) async {
    state = mode;
    await ref.read(themeModeStoreProvider).write(mode);
  }
}

final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(ThemeModeController.new);
