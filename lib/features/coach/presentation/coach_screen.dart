import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/rise_in.dart';
import '../../../core/widgets/soft.dart';
import 'coach_providers.dart';

/// For now the coach is whoever the owner pastes this summary to. An in-app
/// coach arrives in v1.3.
class CoachScreen extends ConsumerWidget {
  const CoachScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final summary = ref.watch(weekSummaryProvider);
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.l, AppSpacing.s, AppSpacing.l, AppSpacing.xxl),
        children: [
          SizedBox(
            height: 48,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Coach', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5)),
            ),
          ),
          const SizedBox(height: AppSpacing.m),
          RiseIn(
            spacing: AppSpacing.l,
            children: [
              SoftWell(
                padding: const EdgeInsets.all(AppSpacing.l + 2),
                radius: AppRadii.card,
                child: Text(
                  'Copy this week\'s summary and paste it into a chat to ask for advice. A coach inside the app arrives in v1.3.',
                  style: TextStyle(color: c.ink, height: 1.45),
                ),
              ),
              if (summary != null) ...[
                SoftCard(
                  padding: const EdgeInsets.all(AppSpacing.l),
                  child: SelectableText(summary, style: const TextStyle(fontSize: 13, height: 1.55, fontFeatures: [FontFeature.tabularFigures()])),
                ),
                FilledButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: summary));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context)
                        ..clearSnackBars()
                        ..showSnackBar(const SnackBar(content: Text('Summary copied')));
                    }
                  },
                  icon: const Icon(Icons.copy_rounded),
                  label: const Text('Copy summary'),
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
