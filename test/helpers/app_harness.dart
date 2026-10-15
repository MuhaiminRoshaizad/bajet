import 'package:bajet/features/accounts/presentation/account_providers.dart';
import 'package:bajet/app/app.dart';
import 'package:bajet/core/database/database_provider.dart';
import 'package:bajet/core/theme/theme_mode.dart';
import 'package:bajet/features/coach/presentation/coach_providers.dart';
import 'package:bajet/features/launch/data/home_surface.dart';
import 'package:bajet/features/ledger/presentation/ledger_providers.dart';
import 'package:bajet/features/plan/domain/plan_repository.dart';
import 'package:bajet/features/plan/presentation/plan_providers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import 'fake_repositories.dart';

/// Wednesday, used as "today" in widget tests so weekday rules are stable.
final testToday = DateTime.utc(2026, 7, 1);

/// With these, the world also holds one account of RM1,500.00.
final demoSettings = PlanSettings(openingDate: testToday, weeklyCap: 5000, buffer: 50000);

/// Pumps the whole app over in-memory fake repositories and returns them so
/// the test can seed and inspect data; [overrides] adds any others. Without
/// [setUpDone] the app opens on first-run setup. drift itself is covered by repository tests against a
/// real in-memory database; widget tests stay on the fakes because drift's
/// stream timers do not run on the widget tester's fake clock.
Future<FakeWorld> pumpApp(
  WidgetTester tester, {
  bool setUpDone = true,
  void Function(FakeWorld world)? seed,
  List<Override> Function(FakeWorld world)? overrides,
}) async {
  // A typical phone: 360 x 780 logical pixels.
  tester.view
    ..physicalSize = const Size(1080, 2340)
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final world = FakeWorld(settings: setUpDone ? demoSettings : null);
  seed?.call(world);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      todayProvider.overrideWithValue(testToday),
      ledgerRepositoryProvider.overrideWithValue(world),
      favouriteRepositoryProvider.overrideWithValue(world.favourites),
      receiptStoreProvider.overrideWithValue(world.receipts),
      homeSurfaceProvider.overrideWithValue(world.home),
      coachKeyStoreProvider.overrideWithValue(world.coachKeys),
      coachClientProvider.overrideWithValue(world.coach),
      planRepositoryProvider.overrideWithValue(world),
      accountRepositoryProvider.overrideWithValue(world),
      photoColoursProvider.overrideWithValue(world.photos),
      themeModeStoreProvider.overrideWithValue(world.themeModes),
      ...?overrides?.call(world),
    ],
    child: const BajetApp(),
  ));
  await tester.pumpAndSettle();
  return world;
}
