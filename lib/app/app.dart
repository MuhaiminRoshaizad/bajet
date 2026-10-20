import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../core/theme/theme_mode.dart';
import '../features/launch/presentation/launch_providers.dart';
import '../features/ledger/presentation/ledger_providers.dart';
import '../features/lock/presentation/lock_providers.dart';
import '../features/lock/presentation/lock_screen.dart';
import '../features/opening/presentation/opening_providers.dart';
import 'dismiss_keyboard.dart';
import 'opening_overlay.dart';
import 'router.dart';
import 'stack_landing.dart';

final _keyboard = DismissKeyboardOnTap();

class BajetApp extends ConsumerWidget {
  const BajetApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Runs once per launch; see receiptCleanupProvider.
    ref.watch(receiptCleanupProvider);
    // Kept alive for the app's lifetime: the launcher shortcuts follow the
    // favourites, and a link that launched the app is held until used.
    ref.watch(homeSurfaceSyncProvider);
    ref.watch(pendingLaunchProvider);
    ref.watch(recentsPrivacySyncProvider);
    return MaterialApp.router(
      title: 'bajet',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ref.watch(themeModeProvider),
      routerConfig: ref.watch(routerProvider),
      builder: (context, child) => Stack(children: [
        LockGate(landOnToday: () => landOnToday(ref), child: child!),
        if (ref.watch(openingProvider)) const Positioned.fill(child: OpeningOverlay()),
      ]),
      actions: {...WidgetsApp.defaultActions, ..._keyboard.actions},
    );
  }
}
