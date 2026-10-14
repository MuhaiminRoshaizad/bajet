import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../features/ledger/presentation/ledger_providers.dart';
import 'router.dart';

class BajetApp extends ConsumerWidget {
  const BajetApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Runs once per launch; see receiptCleanupProvider.
    ref.watch(receiptCleanupProvider);
    return MaterialApp.router(
      title: 'bajet',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      routerConfig: ref.watch(routerProvider),
    );
  }
}
