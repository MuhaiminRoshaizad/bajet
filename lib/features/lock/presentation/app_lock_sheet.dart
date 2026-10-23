import '../../../core/widgets/app_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../domain/app_lock.dart';
import 'lock_providers.dart';

/// Whether the phone has a fingerprint, face or screen lock to check, asked
/// afresh each time the sheet opens, since the user may have just added one.
final lockAvailableProvider = FutureProvider.autoDispose<bool>((ref) => ref.watch(deviceAuthProvider).isAvailable());

/// What Settings shows under App lock.
String lockSummary(LockSettings s) => !s.enabled
    ? 'Off'
    : s.grace == LockGrace.immediately
        ? 'Fingerprint · asks straight away'
        : 'Fingerprint · after ${s.grace.label}';

Future<void> showAppLockSheet(BuildContext context) =>
    showAppSheet<void>(context: context, isScrollControlled: true, builder: (_) => const _AppLockSheet());

class _AppLockSheet extends ConsumerStatefulWidget {
  const _AppLockSheet();

  @override
  ConsumerState<_AppLockSheet> createState() => _AppLockSheetState();
}

class _AppLockSheetState extends ConsumerState<_AppLockSheet> {
  var _busy = false;
  String? _problem;

  Future<void> _toggle(bool on) async {
    final settings = ref.read(lockSettingsProvider.notifier);
    if (!on) return settings.disable();
    setState(() {
      _busy = true;
      _problem = null;
    });
    final outcome = await settings.enable();
    if (!mounted) return;
    if (outcome == AuthOutcome.unavailable) ref.invalidate(lockAvailableProvider);
    setState(() {
      _busy = false;
      _problem = switch (outcome) {
        AuthOutcome.failed || AuthOutcome.lockedOut => "bajet couldn't check it's you, so App lock stays off. Try again in a moment.",
        _ => null,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final settings = ref.watch(lockSettingsProvider);
    // Off is offered whatever the phone says, so the lock can always be
    // switched off.
    final available = ref.watch(lockAvailableProvider).value ?? true;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.s, 0, AppSpacing.s, AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
            child: Text('App lock', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          ),
          if (!available && !settings.enabled)
            Container(
              margin: const EdgeInsets.fromLTRB(AppSpacing.l, AppSpacing.m, AppSpacing.l, 0),
              padding: const EdgeInsets.all(AppSpacing.m),
              decoration: BoxDecoration(color: c.keepSurface, borderRadius: BorderRadius.circular(AppRadii.small)),
              child: Text(
                "Your phone has no screen lock. Add a fingerprint or a screen lock in your phone's settings first, then come back here.",
                style: TextStyle(color: c.ink),
              ),
            ),
          const SizedBox(height: AppSpacing.s),
          SwitchListTile(
            value: settings.enabled,
            onChanged: _busy || (!available && !settings.enabled) ? null : _toggle,
            title: const Text('Lock with fingerprint'),
            subtitle: const Text('Asks for your fingerprint, or your phone PIN, each time bajet opens.'),
          ),
          if (_problem != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
              child: Text(_problem!, style: TextStyle(color: c.bad)),
            ),
          if (settings.enabled) ...[
            const SizedBox(height: AppSpacing.m),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Ask again after'),
                  const SizedBox(height: AppSpacing.s),
                  SegmentedButton<LockGrace>(
                    segments: [for (final g in LockGrace.values) ButtonSegment(value: g, label: Text(g.label))],
                    selected: {settings.grace},
                    showSelectedIcon: false,
                    onSelectionChanged: (s) => ref.read(lockSettingsProvider.notifier).setGrace(s.single),
                  ),
                  const SizedBox(height: AppSpacing.s),
                  Text('How long bajet can sit in the background before it asks again.', style: TextStyle(color: c.muted, fontSize: 13)),
                  const SizedBox(height: AppSpacing.l),
                  Text('The app switcher shows a blank card while the lock is on.', style: TextStyle(color: c.muted, fontSize: 13)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
