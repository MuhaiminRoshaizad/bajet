import 'package:bajet/app/app.dart';
import 'package:bajet/core/database/database_provider.dart';
import 'package:bajet/features/ledger/presentation/ledger_providers.dart';
import 'package:bajet/features/plan/domain/plan_repository.dart';
import 'package:bajet/features/plan/presentation/plan_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_repositories.dart';

/// Wednesday, used as "today" in widget tests so weekday rules are stable.
final testToday = DateTime.utc(2026, 7, 1);

final demoSettings = PlanSettings(openingBalance: 150000, openingDate: testToday, weeklyCap: 5000, buffer: 50000);

/// Pumps the whole app over in-memory fake repositories and returns them so
/// the test can seed and inspect data. Without [setUpDone] the app opens on
/// first-run setup. drift itself is covered by repository tests against a
/// real in-memory database; widget tests stay on the fakes because drift's
/// stream timers do not run on the widget tester's fake clock.
Future<FakeWorld> pumpApp(WidgetTester tester, {bool setUpDone = true, void Function(FakeWorld world)? seed}) async {
  final world = FakeWorld(settings: setUpDone ? demoSettings : null);
  seed?.call(world);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      todayProvider.overrideWithValue(testToday),
      ledgerRepositoryProvider.overrideWithValue(world),
      favouriteRepositoryProvider.overrideWithValue(world.favourites),
      planRepositoryProvider.overrideWithValue(world),
    ],
    child: const BajetApp(),
  ));
  await tester.pumpAndSettle();
  return world;
}
