import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/soft.dart';
import '../domain/coach_client.dart';
import 'coach_providers.dart';

/// Settings → Coach: where the owner's own Anthropic key goes in or comes
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
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(const SnackBar(content: Text('Key saved')));
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
    if (confirmed == true) await ref.read(coachKeyProvider.notifier).remove();
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
              'Each one sends your question and a summary of this week and month to Anthropic. '
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
        ],
      ),
    );
  }
}
