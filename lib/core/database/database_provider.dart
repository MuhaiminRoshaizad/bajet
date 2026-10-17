import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../dates/clock.dart';
import 'app_database.dart';

/// The single database for the app's lifetime. Tests override it with an
/// in-memory database.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

/// Today's calendar day. It moves on at midnight, and is read again
/// whenever the app comes back to the front, since Android can keep the app
/// alive in the background across days; reading it again on the same day
/// changes nothing. Overridden in tests to pin the date.
final todayProvider = Provider<DateTime>((ref) {
  final now = ref.watch(clockProvider)();
  final midnight = Timer(DateTime(now.year, now.month, now.day + 1).difference(now), ref.invalidateSelf);
  final resumed = AppLifecycleListener(onResume: ref.invalidateSelf);
  ref.onDispose(() {
    midnight.cancel();
    resumed.dispose();
  });
  return DateTime.utc(now.year, now.month, now.day);
});
