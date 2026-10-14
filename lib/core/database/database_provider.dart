import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart';

/// The single database for the app's lifetime. Tests override it with an
/// in-memory database.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

/// Today's calendar day. Overridden in tests to pin the date.
final todayProvider = Provider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime.utc(now.year, now.month, now.day);
});
