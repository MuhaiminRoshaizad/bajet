import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_colors.dart';
import '../features/lock/domain/app_lock.dart';
import '../features/lock/presentation/lock_providers.dart';
import '../features/opening/presentation/titanium_card.dart';

/// Back at the top of the app no longer closes bajet straight away: from
/// another tab it goes to Today, and on Today it asks first. Back inside a
/// screen or a sheet is untouched, since that pops before it reaches here.
/// Home and the app switcher can always leave; Android gives no app a way
/// to stop them.
class LeaveGuard extends ConsumerWidget {
  const LeaveGuard({super.key, required this.onToday, required this.goToday, required this.child});

  final bool onToday;
  final VoidCallback goToday;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) => PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) async {
          if (didPop) return;
          if (!onToday) return goToday();
          if (await confirmLeave(context, ref.read(lockSettingsProvider))) await SystemNavigator.pop();
        },
        child: child,
      );
}

/// What leaving costs with this App lock setting, if anything.
String? leaveLockLine(LockSettings lock) => !lock.enabled
    ? null
    : lock.grace == LockGrace.immediately
        ? "App lock is on, so you'll need your fingerprint to get back in."
        : "If you're away for more than ${lock.grace.label}, you'll need your fingerprint to get back in.";

/// True when the user chose Leave. Leaving loses nothing, so Leave is the
/// ordinary filled button, not the warning colour.
Future<bool> confirmLeave(BuildContext context, LockSettings lock) async {
  final c = context.colors;
  final line = leaveLockLine(lock);
  final leave = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      icon: const Center(child: AppIconTile()),
      title: const Text('Leave bajet?'),
      content: Text(['Everything you\'ve logged is saved.', ?line].join(' '), textAlign: TextAlign.center, style: TextStyle(color: c.muted)),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Stay')),
        FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Leave')),
      ],
    ),
  );
  return leave ?? false;
}
