import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../domain/coach_settings.dart';
import 'coach_avatar.dart';
import 'coach_chats.dart';
import 'coach_controller.dart';
import 'coach_providers.dart';

/// The sheet that switches the coach's face: from a chat, that chat's
/// coach, keeping its messages; from Settings → Coach, the face new chats
/// start with.
Future<void> showCoachPicker(BuildContext context, {int? chat}) => showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (_) => _CoachPicker(chat: chat),
    );

class _CoachPicker extends ConsumerWidget {
  const _CoachPicker({this.chat});

  final int? chat;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final defaults = (ref.watch(coachSettingsProvider).value ?? const CoachSettings()).face;
    final current = chat == null ? defaults : ref.watch(coachChatsProvider).byId(chat!)?.face ?? defaults;
    final idle = ref.watch(coachIdleMotionProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.l, 0, AppSpacing.l, AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Choose your coach', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.xs),
          Text('Same memory and figures, whoever you pick. How they talk is set under Personality.', style: TextStyle(color: c.muted)),
          const SizedBox(height: AppSpacing.l),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: AppSpacing.m,
            crossAxisSpacing: AppSpacing.m,
            childAspectRatio: 1.05,
            children: [
              for (final face in CoachFace.values)
                Semantics(
                  selected: face == current,
                  button: true,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppRadii.card),
                    onTap: () => _choose(context, ref, face),
                    child: Ink(
                      decoration: BoxDecoration(
                        color: c.background,
                        borderRadius: BorderRadius.circular(AppRadii.card),
                        border: Border.all(color: face == current ? c.primary : c.line, width: face == current ? 2 : 1),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CoachAvatar(face: face, size: 64, idle: idle),
                          const SizedBox(height: AppSpacing.s),
                          Text(face.label, style: const TextStyle(fontWeight: FontWeight.w700)),
                          Text(face.look, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: c.muted, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _choose(BuildContext context, WidgetRef ref, CoachFace face) async {
    // Everything is read before the sheet closes: once it has, its ref is
    // gone, and Use it would quietly do nothing.
    final messenger = ScaffoldMessenger.of(context);
    final repo = ref.read(coachSettingsRepositoryProvider);
    final chats = ref.read(coachChatsProvider.notifier);
    final controller = chat == null ? null : ref.read(coachControllerProvider(chat!).notifier);
    final settings = ref.read(coachSettingsProvider).value ?? const CoachSettings();
    final was = chat == null ? settings.face : ref.read(coachChatsProvider).byId(chat!)?.face ?? settings.face;
    Navigator.of(context).pop();
    if (face == was) return;
    // The face picked last is the one new chats start with too.
    await repo.saveSettings(settings.copyWith(face: face));
    await controller?.switchFace(face);
    // bajety's joke is the knows-too-much voice, so it offers it once picked.
    if (face == CoachFace.bajety && settings.personality != CoachPersonality.seesEverything) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: const Text('bajety pairs well with Sees Everything 😉'),
          action: SnackBarAction(
            label: 'Use it',
            onPressed: () async {
              final now = await repo.watchSettings().first;
              await repo.saveSettings(now.copyWith(personality: CoachPersonality.seesEverything));
              if (chat != null) await chats.setCoach(chat!, personality: CoachPersonality.seesEverything);
            },
          ),
        ));
    }
  }
}
