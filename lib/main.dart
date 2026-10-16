import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/database/app_database.dart';
import 'core/database/database_provider.dart';
import 'core/database/demo_data.dart';
import 'core/theme/theme_mode.dart';
import 'core/widgets/rise_in.dart';
import 'features/lock/data/file_lock_settings_store.dart';
import 'features/lock/presentation/lock_providers.dart';
import 'features/opening/presentation/opening_providers.dart';

/// `flutter run --dart-define=BAJET_DEMO=true` starts on made-up data held
/// in memory, for screenshots and demos. The real database is never opened,
/// and everything is gone when the app closes.
const demo = bool.fromEnvironment('BAJET_DEMO');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final theme = initialThemeModeProvider.overrideWithValue(await FileThemeModeStore().read());
  final lock = initialLockSettingsProvider.overrideWithValue(await FileLockSettingsStore().read());
  final opening = [playOpeningProvider.overrideWithValue(true), initialEntranceHoldProvider.overrideWithValue(true)];
  if (!demo) return runApp(ProviderScope(overrides: [theme, lock, ...opening], child: const BajetApp()));
  final db = AppDatabase(NativeDatabase.memory());
  final now = DateTime.now();
  await fillWithDemoData(db, DateTime.utc(now.year, now.month, now.day));
  runApp(ProviderScope(overrides: [theme, lock, ...opening, databaseProvider.overrideWithValue(db)], child: const BajetApp()));
}
