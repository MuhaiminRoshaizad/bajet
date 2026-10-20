import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/soft.dart';
import '../domain/coach_settings.dart';
import 'coach_avatar.dart';
import 'coach_chats.dart';
import 'coach_controller.dart';

/// One chat's coach and personality, changed for that chat only. The
/// sheet stays open as they change, so the chat can be seen answering to
/// its new coach.
Future<void> showChatSettings(BuildContext context, int chat) => showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (_) => _ChatSettings(chat: chat),
    );

class _ChatSettings extends ConsumerWidget {
  const _ChatSettings({required this.chat});

  final int chat;

  Future<void> _pickFace(BuildContext context, WidgetRef ref, CoachFace face, CoachPersonality personality) async {
    final messenger = ScaffoldMessenger.of(context);
    final controller = ref.read(coachControllerProvider(chat).notifier);
    await controller.switchFace(face);
    // bajety's joke is the knows-too-much voice, so it offers it once picked.
    if (face == CoachFace.bajety && personality != CoachPersonality.seesEverything) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: const Text('bajety pairs well with Sees Everything 😉'),
          action: SnackBarAction(label: 'Use it', onPressed: () => controller.setPersonality(CoachPersonality.seesEverything)),
        ));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final thread = ref.watch(coachChatsProvider).byId(chat);
    if (thread == null) return const SizedBox.shrink();
    final idle = ref.watch(coachIdleMotionProvider);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.l, 0, AppSpacing.l, AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text("This chat's coach", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.xs),
          Text('Only this chat changes. Same memory and figures, whoever you pick.', style: TextStyle(color: c.muted)),
          const SizedBox(height: AppSpacing.l),
          Row(
            children: [
              for (final face in CoachFace.values)
                Expanded(
                  child: _FaceChoice(
                    face: face,
                    selected: face == thread.face,
                    idle: idle,
                    onTap: () => _pickFace(context, ref, face, thread.personality),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.l),
          Text('Personality', style: TextStyle(color: c.muted, fontWeight: FontWeight.w700)),
          RadioGroup<CoachPersonality>(
            groupValue: thread.personality,
            onChanged: (p) {
              if (p != null) ref.read(coachControllerProvider(chat).notifier).setPersonality(p);
            },
            child: Column(
              children: [
                for (final p in CoachPersonality.values)
                  RadioListTile(
                    contentPadding: EdgeInsets.zero,
                    value: p,
                    title: Text(p.label, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(p.about, style: TextStyle(color: c.muted)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s),
          Text('New chats start with the coach and personality in Coach settings.', style: TextStyle(color: c.muted, fontSize: 13)),
        ],
      ),
    );
  }
}

/// A coach to pick: pressed into the surface while it is this chat's.
class _FaceChoice extends StatelessWidget {
  const _FaceChoice({required this.face, required this.selected, required this.idle, required this.onTap});

  final CoachFace face;
  final bool selected;
  final bool idle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final content = Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.m),
      child: Column(
        children: [
          AnimatedScale(
            scale: selected ? 1.06 : 1,
            duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 380),
            curve: Curves.easeOutBack,
            child: CoachAvatar(face: face, size: 52, idle: idle),
          ),
          const SizedBox(height: AppSpacing.s),
          Text(face.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: selected ? c.primary : c.ink)),
        ],
      ),
    );
    return Semantics(
      button: true,
      selected: selected,
      label: '${face.label}, ${face.look}',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.card),
        child: AnimatedSwitcher(
          duration: AppMotion.fast,
          child: selected ? SoftWell(key: const ValueKey('on'), radius: AppRadii.card, padding: EdgeInsets.zero, child: content) : KeyedSubtree(key: const ValueKey('off'), child: content),
        ),
      ),
    );
  }
}
