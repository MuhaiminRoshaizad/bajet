import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/navigation/routes.dart';
import '../features/accounts/presentation/account_settings_screen.dart';
import '../features/accounts/presentation/account_stack.dart';
import '../features/accounts/presentation/account_view_screen.dart';
import '../features/accounts/presentation/accounts_screen.dart';
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

  // Pages opened from a tab go on this navigator, above the shell, so they
  // fill the screen without the bottom bar. Only the four tabs show it.
  final root = GlobalKey<NavigatorState>();
  GoRoute page(String path, Widget screen, {List<RouteBase> routes = const []}) =>
      GoRoute(path: path, parentNavigatorKey: root, builder: (context, state) => screen, routes: routes);

  final router = GoRouter(
    navigatorKey: root,
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
          initialRange: (
            period: InsightsPeriod.values.asNameMap()[state.uri.queryParameters['period']] ?? InsightsPeriod.week,
            offset: math.min(0, int.tryParse(state.uri.queryParameters['offset'] ?? '') ?? 0),
          ),
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
                page('history', const HistoryScreen()),
                // Fades in rather than sliding, so the stack can fly up from
                // Today and spread out where it lands.
                GoRoute(
                  path: 'accounts',
                  parentNavigatorKey: root,
                  // Draws its own arrival, the cards sliding out of Today's
                  // stack, so the route only times it and keeps Today below.
                  pageBuilder: (context, state) => CustomTransitionPage(
                    key: state.pageKey,
                    opaque: false,
                    transitionDuration: AccountsScreen.duration,
                    reverseTransitionDuration: AccountsScreen.reverseDuration,
                    transitionsBuilder: (context, animation, _, child) => child,
                    child: AccountsScreen(from: state.extra as StackPlaces?),
                  ),
                  routes: [
                    // The page draws its own arrival, the card flying out of
                    // the stack, so the route itself only times it.
                    GoRoute(
                      path: ':id',
                      parentNavigatorKey: root,
                      pageBuilder: (context, state) => CustomTransitionPage(
                        key: state.pageKey,
                        opaque: false,
                        transitionDuration: AccountViewScreen.duration,
                        reverseTransitionDuration: AccountViewScreen.reverseDuration,
                        transitionsBuilder: (context, animation, _, child) => child,
                        child: AccountViewScreen(accountId: int.parse(state.pathParameters['id']!), places: state.extra as CardPlaces?),
                      ),
                    ),
                  ],
                ),
                page('checkin', const CheckinScreen()),
                page('settings', const SettingsScreen(), routes: [
                  page('accounts', const AccountSettingsScreen()),
                  page('favourites', const FavouritesScreen()),
                  page('rhythm', const RhythmScreen()),
                  page('recurring', const RecurringScreen()),
                  page('goals', const GoalsScreen()),
                  page('events', const EventsScreen()),
                  page('backup', const BackupScreen()),
                  page('coach', const CoachKeyScreen()),
                ]),
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
