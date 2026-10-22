import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/card_group.dart';
import '../../../core/widgets/confirm_delete.dart';
import '../../../core/widgets/done_bar.dart';
import '../../../core/widgets/soft.dart';
import '../domain/coach_client.dart';
import '../domain/coach_memory.dart';
import '../domain/coach_settings.dart';
import 'coach_avatar.dart';
import 'coach_chats.dart';
import 'coach_picker.dart';
import 'coach_providers.dart';

/// Settings → Coach: where the user's own Anthropic key goes in or comes
/// out. The key is never shown again once saved.
class CoachKeyScreen extends ConsumerStatefulWidget {
  const CoachKeyScreen({super.key});

  @override
  ConsumerState<CoachKeyScreen> createState() => _CoachKeyScreenState();
}

class _CoachKeyScreenState extends ConsumerState<CoachKeyScreen> {
  final _form = GlobalKey<FormState>();
  final _field = GlobalKey<FormFieldState<String>>();
  final _key = TextEditingController();

  @override
  void dispose() {
    _key.dispose();
    super.dispose();
  }

  static String? _validate(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Paste your key from the Anthropic Console';
    if (!v.startsWith('sk-ant-') || v.length < 30) return 'That is not an Anthropic key. They start with sk-ant-';
    return null;
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    await ref.read(coachKeyProvider.notifier).save(_key.text);
    _key.clear();
    if (!mounted) return;
    FocusScope.of(context).unfocus();
    showBar(ScaffoldMessenger.of(context), 'Key saved');
  }

  Future<void> _remove() async {
    final c = context.colors;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove the key?'),
        content: const Text('The coach stops answering until a key is added again. Your conversations and data are not affected.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Keep it')),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: c.bad, foregroundColor: c.onBad),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    await ref.read(coachKeyProvider.notifier).remove();
    showBar(messenger, 'Key removed. The coach is off until a key is added.');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final saved = ref.watch(coachKeyProvider).value != null;
    final used = ref.watch(coachUsedTodayProvider).value ?? 0;
    return Scaffold(
      appBar: AppBar(title: const Text('Coach')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.l),
        children: [
          SoftWell(
            radius: AppRadii.card,
            padding: const EdgeInsets.all(AppSpacing.l + 2),
            child: Text(
              'The coach uses your own Anthropic API key, from console.anthropic.com under API keys. '
              'Questions are billed to your Anthropic account, at most $coachDailyLimit a day. '
              'Each one sends your question and only the figures the coach looks up to Anthropic. '
              'The key stays in this phone\'s secure storage and is never shown again or backed up.',
              style: TextStyle(color: c.ink, height: 1.45),
            ),
          ),
          const SizedBox(height: AppSpacing.l),
          if (saved) ...[
            SoftCard(
              child: Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: c.good),
                  const SizedBox(width: AppSpacing.m),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('A key is saved', style: TextStyle(fontWeight: FontWeight.w700)),
                        Text('$used of $coachDailyLimit questions used today', style: TextStyle(color: c.muted, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.l),
            Text('To change it, paste a new key below.', style: TextStyle(color: c.muted)),
            const SizedBox(height: AppSpacing.s),
          ],
          Form(
            key: _form,
            child: Focus(
              skipTraversal: true,
              // Reward early, punish late: check once the field is left.
              onFocusChange: (focused) {
                if (!focused && _key.text.isNotEmpty) _field.currentState?.validate();
              },
              child: TextFormField(
                key: _field,
                controller: _key,
                obscureText: true,
                autocorrect: false,
                enableSuggestions: false,
                keyboardType: TextInputType.visiblePassword,
                autovalidateMode: AutovalidateMode.onUserInteractionIfError,
                validator: _validate,
                onFieldSubmitted: (_) => _save(),
                decoration: const InputDecoration(labelText: 'Anthropic API key', hintText: 'sk-ant-…'),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.l),
          FilledButton(onPressed: _save, style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)), child: Text(saved ? 'Replace the key' : 'Save the key')),
          if (saved) ...[
            const SizedBox(height: AppSpacing.s),
            TextButton(
              onPressed: _remove,
              style: TextButton.styleFrom(foregroundColor: c.bad, minimumSize: const Size.fromHeight(48)),
              child: const Text('Remove the key'),
            ),
          ],
          const SizedBox(height: AppSpacing.xxl),
          const _YourCoach(),
          const SizedBox(height: AppSpacing.xxl),
          const _PersonalityPicker(),
          const SizedBox(height: AppSpacing.xxl),
          const _Memory(),
        ],
      ),
    );
  }
}

/// How the coach talks: one of the fixed personalities, each shown saying
/// the same thing so the difference is plain.
class _PersonalityPicker extends ConsumerWidget {
  const _PersonalityPicker();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final settings = ref.watch(coachSettingsProvider).value ?? const CoachSettings();
    return CardGroup(
      label: 'Personality for new chats',
      children: [
        RadioGroup<CoachPersonality>(
          groupValue: settings.personality,
          onChanged: (p) {
            if (p != null) ref.read(coachSettingsRepositoryProvider).saveSettings(settings.copyWith(personality: p));
          },
          child: Column(
            children: [
              for (final p in CoachPersonality.values)
                RadioListTile(
                  value: p,
                  title: Text(p.label, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Text('${p.about}\n"${p.sample}"', style: TextStyle(color: c.muted, height: 1.4)),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Whether the chat is remembered, and the way to forget it.
class _Memory extends ConsumerWidget {
  const _Memory();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final remember = (ref.watch(coachSettingsProvider).value ?? const CoachSettings()).remember;
    final count = ref.watch(coachChatsProvider).said.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CardGroup(
          label: 'Memory',
          children: [
            SwitchListTile(
              title: const Text('Remember our chats', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(
                'Kept on this phone only, never in a backup. Each question sends the last $coachMemoryWindow messages, and the coach '
                'searches older ones only when you ask about them. Turning this off forgets what was kept.',
                style: TextStyle(color: c.muted, height: 1.4),
              ),
              value: remember,
              onChanged: (on) => ref.read(coachChatsProvider.notifier).setRemember(on),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.m),
        OutlinedButton(
          onPressed: count == 0 ? null : () => _forget(context, ref, count),
          style: OutlinedButton.styleFrom(foregroundColor: c.bad, side: BorderSide(color: c.bad), minimumSize: const Size.fromHeight(52)),
          child: Text(count == 0 ? 'Nothing to forget' : 'Forget everything ($count ${count == 1 ? 'message' : 'messages'})'),
        ),
      ],
    );
  }

  Future<void> _forget(BuildContext context, WidgetRef ref, int count) async {
    final sure = await confirmDelete(
      context,
      title: 'Forget everything?',
      message: 'The coach forgets all $count ${count == 1 ? 'message' : 'messages'} and the chat empties. Your entries, accounts and figures stay exactly as they are.',
      action: 'Forget',
    );
    if (!sure || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final controller = ref.read(coachChatsProvider.notifier);
    final gone = await controller.forget();
    showBar(messenger, 'Chat forgotten', undo: () => controller.restore(gone));
  }
}

/// The coach's face, opening the same picker as the Coach tab's header.
class _YourCoach extends ConsumerWidget {
  const _YourCoach();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final face = (ref.watch(coachSettingsProvider).value ?? const CoachSettings()).face;
    return CardGroup(
      label: 'Coach for new chats',
      children: [
        ListTile(
          minTileHeight: 72,
          leading: CoachAvatar(face: face, size: 44, idle: ref.watch(coachIdleMotionProvider)),
          title: Text(face.label, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(face.look, style: TextStyle(color: c.muted)),
          trailing: Icon(Icons.chevron_right_rounded, color: c.muted),
          onTap: () => showCoachPicker(context),
        ),
      ],
    );
  }
}

