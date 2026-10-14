import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/navigation/routes.dart';
import '../features/plan/presentation/plan_providers.dart';
import '../features/backup/presentation/backup_screen.dart';
import '../features/checkin/presentation/checkin_screen.dart';
import '../features/coach/presentation/coach_key_screen.dart';
import '../features/coach/presentation/coach_screen.dart';
import '../features/insights/domain/insights.dart';
import '../features/insights/presentation/insights_screen.dart';
import '../features/ledger/presentation/history_screen.dart';
import '../features/plan/presentation/runway_screen.dart';
import '../features/report/presentation/report_screen.dart';
import '../features/settings/presentation/events_screen.dart';
import '../features/settings/presentation/favourites_screen.dart';
import '../features/settings/presentation/goals_screen.dart';
import '../features/settings/presentation/recurring_screen.dart';
import '../features/settings/presentation/rhythm_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/setup/presentation/setup_screen.dart';
import '../features/today/presentation/today_screen.dart';
import 'shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // Re-runs the redirect whenever settings change, so finishing setup moves
  // straight to Today without the setup screen navigating itself.
  final settingsChanged = ValueNotifier(0);
  ref.listen(settingsProvider, (_, _) => settingsChanged.value++);

  final router = GoRouter(
    initialLocation: Routes.today,
    refreshListenable: settingsChanged,
    redirect: (context, state) {
      final settings = ref.read(settingsProvider);
      final at = state.matchedLocation;
      if (!settings.hasValue) return at == Routes.loading ? null : Routes.loading;
      if (settings.value == null) return at == Routes.setup ? null : Routes.setup;
      if (at == Routes.setup || at == Routes.loading) return Routes.today;
      return null;
    },
    routes: [
      GoRoute(path: Routes.loading, builder: (context, state) => const Scaffold()),
      GoRoute(path: Routes.setup, builder: (context, state) => const SetupScreen()),
      GoRoute(
        path: Routes.report,
        builder: (context, state) => ReportScreen(
          initialPeriod: InsightsPeriod.values.asNameMap()[state.uri.queryParameters['period']] ?? InsightsPeriod.week,
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.today,
              builder: (context, state) => const TodayScreen(),
              routes: [
                GoRoute(path: 'history', builder: (context, state) => const HistoryScreen()),
                GoRoute(path: 'checkin', builder: (context, state) => const CheckinScreen()),
                GoRoute(
                  path: 'settings',
                  builder: (context, state) => const SettingsScreen(),
                  routes: [
                    GoRoute(path: 'favourites', builder: (context, state) => const FavouritesScreen()),
                    GoRoute(path: 'rhythm', builder: (context, state) => const RhythmScreen()),
                    GoRoute(path: 'recurring', builder: (context, state) => const RecurringScreen()),
                    GoRoute(path: 'goals', builder: (context, state) => const GoalsScreen()),
                    GoRoute(path: 'events', builder: (context, state) => const EventsScreen()),
                    GoRoute(path: 'backup', builder: (context, state) => const BackupScreen()),
                    GoRoute(path: 'coach', builder: (context, state) => const CoachKeyScreen()),
                  ],
                ),
              ],
            ),
          ]),
          _branch(Routes.runway, const RunwayScreen()),
          _branch(Routes.insights, const InsightsScreen()),
          _branch(Routes.coach, const CoachScreen()),
        ],
      ),
    ],
  );
  ref.onDispose(() {
    router.dispose();
    settingsChanged.dispose();
  });
  return router;
});

StatefulShellBranch _branch(String path, Widget screen) =>
    StatefulShellBranch(routes: [GoRoute(path: path, builder: (context, state) => screen)]);
