import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/navigation/routes.dart';
import '../core/widgets/coming_soon.dart';
import '../features/plan/presentation/plan_providers.dart';
import '../features/ledger/presentation/history_screen.dart';
import '../features/plan/presentation/runway_screen.dart';
import '../features/settings/presentation/favourites_screen.dart';
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
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.today,
              builder: (context, state) => const TodayScreen(),
              routes: [
                GoRoute(path: 'history', builder: (context, state) => const HistoryScreen()),
                GoRoute(
                  path: 'settings',
                  builder: (context, state) => const SettingsScreen(),
                  routes: [
                    GoRoute(path: 'favourites', builder: (context, state) => const FavouritesScreen()),
                    GoRoute(path: 'rhythm', builder: (context, state) => const RhythmScreen()),
                    GoRoute(path: 'recurring', builder: (context, state) => const RecurringScreen()),
                  ],
                ),
              ],
            ),
          ]),
          _branch(Routes.runway, const RunwayScreen()),
          _branch(
            Routes.insights,
            const ComingSoon(title: 'Insights', icon: Icons.bar_chart_rounded, message: 'Where the money goes, by category, week and month. Arrives in v1.1.'),
          ),
          _branch(
            Routes.coach,
            const ComingSoon(title: 'Coach', icon: Icons.chat_bubble_rounded, message: 'A coach that reads your logs and knows your rules. Arrives in v1.3.'),
          ),
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
