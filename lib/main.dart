import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/database/app_database.dart';
import 'core/database/database_provider.dart';
import 'core/database/demo_data.dart';

/// `flutter run --dart-define=BAJET_DEMO=true` starts on made-up data held
/// in memory, for screenshots and demos. The real database is never opened,
/// and everything is gone when the app closes.
const demo = bool.fromEnvironment('BAJET_DEMO');

Future<void> main() async {
  if (!demo) return runApp(const ProviderScope(child: BajetApp()));
  WidgetsFlutterBinding.ensureInitialized();
  final db = AppDatabase(NativeDatabase.memory());
  final now = DateTime.now();
  await fillWithDemoData(db, DateTime.utc(now.year, now.month, now.day));
  runApp(ProviderScope(overrides: [databaseProvider.overrideWithValue(db)], child: const BajetApp()));
}
