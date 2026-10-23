import '../../../core/widgets/app_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/device_flags.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/soft.dart';
import '../../lock/presentation/lock_providers.dart';
import '../domain/ledger_models.dart';
import 'spend_kind_choice.dart';

/// Explains wants and needs in a sheet over whichever page is open, with a
/// quick check on an everyday example.
Future<void> showKindsExplainer(BuildContext context) => showAppSheet<void>(
      context: context,
      // Over whichever page is open, the bar included.
      useRootNavigator: true,
      isScrollControlled: true,
      builder: (context) => const _KindsExplainer(),
    );

class _KindsExplainer extends StatefulWidget {
  const _KindsExplainer();

  @override
  State<_KindsExplainer> createState() => _KindsExplainerState();
}

class _KindsExplainerState extends State<_KindsExplainer> {
  SpendKind? _answer;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final still = MediaQuery.disableAnimationsOf(context);
    Widget kind(SpendKind k, String says) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.m),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(padding: const EdgeInsets.only(top: 3), child: CircleAvatar(backgroundColor: k.colour(c), radius: 8)),
            const SizedBox(width: AppSpacing.m),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${k.label}s', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                Text(says, style: TextStyle(color: c.muted, height: 1.4)),
              ]),
            ),
          ]),
        );
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.l),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Not all spending is a choice', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.s),
          Text(
            'bajet sorts each spend two ways. Only wants count toward your weekly allowance. Needs still come off your balance and show in Insights.',
            style: TextStyle(color: c.muted, height: 1.4),
          ),
          const SizedBox(height: AppSpacing.l),
          kind(SpendKind.want, 'You chose it: eating out, snacks, treats.'),
          kind(SpendKind.need, "You'd buy it anyway, or family asked: toothpaste, medicine, a parent's groceries."),
          SoftWell(
            padding: const EdgeInsets.all(AppSpacing.l),
            child: const Text('Not sure? Ask: could I have skipped it, or waited a few weeks, without harm? Then it is a want.', style: TextStyle(height: 1.4)),
          ),
          const SizedBox(height: AppSpacing.l),
          Text('Quick check: toothpaste that ran out', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.muted)),
          const SizedBox(height: AppSpacing.s),
          Wrap(spacing: AppSpacing.s, children: [
            for (final k in SpendKind.values)
              ChoiceChip(
                key: ValueKey('check-${k.name}'),
                avatar: CircleAvatar(backgroundColor: k.colour(c), radius: 8),
                label: Text(k.label),
                selected: _answer == k,
                onSelected: (_) => setState(() => _answer = k),
              ),
          ]),
          AnimatedSize(
            duration: still ? Duration.zero : AppMotion.enter,
            curve: Curves.easeOutBack,
            alignment: Alignment.topLeft,
            child: switch (_answer) {
              null => const SizedBox(width: double.infinity),
              SpendKind.need => _Reply("Right: you'd have bought it anyway.", c.good),
              SpendKind.want => _Reply("Not quite: you'd have bought it anyway, so it is a need.", c.muted),
            },
          ),
          const SizedBox(height: AppSpacing.l),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

class _Reply extends StatelessWidget {
  const _Reply(this.text, this.colour);

  final String text;
  final Color colour;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: AppSpacing.s),
        child: Text(text, style: TextStyle(color: colour, fontSize: 12.5, fontWeight: FontWeight.w600)),
      );
}

/// Shows the explainer once on this phone, the first time the app is open
/// past the lock, so the change to the allowance is never a surprise.
class KindsExplainerHost extends ConsumerStatefulWidget {
  const KindsExplainerHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<KindsExplainerHost> createState() => _KindsExplainerHostState();
}

class _KindsExplainerHostState extends ConsumerState<KindsExplainerHost> {
  /// Set as it is shown, since the flag is saved a moment later and both
  /// triggers can fire before then.
  var _shown = false;

  @override
  void initState() {
    super.initState();
    ref.listenManual(deviceFlagProvider(DeviceFlag.kindsExplained), (_, _) => Future.microtask(_explain), fireImmediately: true);
    ref.listenManual(unlockFlightProvider, (was, flying) {
      if (was == true && !flying) Future.microtask(_explain);
    });
  }

  Future<void> _explain() async {
    if (!mounted) return;
    final seen = ref.read(deviceFlagProvider(DeviceFlag.kindsExplained)).value;
    if (_shown || seen != false || ref.read(appLockProvider) || ref.read(unlockFlightProvider)) return;
    _shown = true;
    final flags = ref.read(deviceFlagsProvider);
    await flags.set(DeviceFlag.kindsExplained, true);
    ref.invalidate(deviceFlagProvider(DeviceFlag.kindsExplained));
    if (mounted) await showKindsExplainer(context);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
