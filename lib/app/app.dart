import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../core/theme/theme_mode.dart';
import '../features/launch/presentation/launch_providers.dart';
import '../features/ledger/presentation/ledger_providers.dart';
import 'dismiss_keyboard.dart';
import 'router.dart';

final _keyboard = DismissKeyboardOnTap();

class BajetApp extends ConsumerWidget {
  const BajetApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Runs once per launch; see receiptCleanupProvider.
    ref.watch(receiptCleanupProvider);
    // Kept alive for the app's lifetime: the home-screen widget and shortcuts
    // follow the data, and a link that launched the app is held until used.
    ref.watch(homeSurfaceSyncProvider);
    ref.watch(pendingLaunchProvider);
    return MaterialApp.router(
      title: 'bajet',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ref.watch(themeModeProvider),
      routerConfig: ref.watch(routerProvider),
      actions: {...WidgetsApp.defaultActions, ..._keyboard.actions},
    );
  }
}
