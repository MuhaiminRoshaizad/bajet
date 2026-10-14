import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/widgets/coming_soon.dart';
import 'shell.dart';

abstract final class Routes {
  static const today = '/today';
  static const runway = '/runway';
  static const insights = '/insights';
  static const coach = '/coach';
}

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: Routes.today,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(navigationShell: shell),
        branches: [
          _branch(Routes.today, const ComingSoon(title: 'Today', icon: Icons.home_rounded, message: 'Your balance, this week and the goal will live here.')),
          _branch(Routes.runway, const ComingSoon(title: 'Runway', icon: Icons.show_chart_rounded, message: 'The projected balance up to buy day will live here.')),
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
  ref.onDispose(router.dispose);
  return router;
});

StatefulShellBranch _branch(String path, Widget screen) =>
    StatefulShellBranch(routes: [GoRoute(path: path, builder: (context, state) => screen)]);
