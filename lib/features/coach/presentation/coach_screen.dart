import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/navigation/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/soft.dart';
import '../domain/coach_client.dart';
import '../domain/coach_prompt.dart';
import 'coach_controller.dart';
import 'coach_providers.dart';

/// Ask about your money. Answers come from Anthropic using the owner's own
/// key; the question box stays pinned to the bottom of the screen.
class CoachScreen extends ConsumerStatefulWidget {
  const CoachScreen({super.key});

  @override
  ConsumerState<CoachScreen> createState() => _CoachScreenState();
}

class _CoachScreenState extends ConsumerState<CoachScreen> {
  final _question = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _question.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send([String? text]) async {
    final question = text ?? _question.text;
    if (question.trim().isEmpty) return;
    _question.clear();
    await ref.read(coachControllerProvider.notifier).ask(question);
  }

  Future<void> _copySummary() async {
    final summary = ref.read(weekSummaryProvider);
    if (summary == null) return;
    await Clipboard.setData(ClipboardData(text: summary));
    if (mounted) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(content: Text('Summary copied')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final hasKey = ref.watch(coachKeyProvider).value != null;
    final chat = ref.watch(coachControllerProvider);
    final used = ref.watch(coachUsedTodayProvider).value ?? 0;
    // Watched so the figures the coach is given stay loaded; the controller
    // only reads them, and an unwatched provider never loads its inputs.
    ref.watch(coachDataProvider);
    // Keep the newest message in view as the conversation grows.
    ref.listen(coachControllerProvider, (_, _) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      });
    });

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.l, AppSpacing.s, AppSpacing.l, 0),
            child: SizedBox(
              height: 48,
              child: Row(
                children: [
                  Text('Coach', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                  const SizedBox(width: AppSpacing.s),
                  // All the spare width goes before the pill, so it and the copy
                  // button sit at the edge; the pill may still shorten at large
                  // text sizes.
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: !hasKey
                          ? null
                          : Semantics(
                              label: '$used of $coachDailyLimit questions used today',
                              excludeSemantics: true,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.xs + 1),
                                decoration: BoxDecoration(color: c.primarySoft, borderRadius: BorderRadius.circular(AppRadii.pill)),
                                child: Text(
                                  '${coachDailyLimit - used} left today',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                    ),
                  ),
                  IconButton(onPressed: _copySummary, icon: const Icon(Icons.copy_rounded), tooltip: "Copy this week's summary"),
                ],
              ),
            ),
          ),
          Expanded(
            child: !hasKey
                ? EmptyState(
                    icon: Icons.forum_outlined,
                    title: 'Ask about your money',
                    message: 'The coach looks up your own figures to answer, using your own Anthropic API key.',
                    actionLabel: 'Add your key',
                    onAction: () => context.push(Routes.coachKey),
                    secondaryLabel: "Copy this week's summary",
                    onSecondary: _copySummary,
                  )
                : ListView(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(AppSpacing.l, AppSpacing.m, AppSpacing.l, AppSpacing.l),
                    children: [
                      if (chat.messages.isEmpty)
                        SoftWell(
                          radius: AppRadii.card,
                          padding: const EdgeInsets.all(AppSpacing.l + 2),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Ask about your money', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                'The coach looks up your weeks, months, accounts and plan to answer. Each question sends '
                                'only what it looked up to Anthropic with your key.',
                                style: TextStyle(color: c.muted, height: 1.4),
                              ),
                            ],
                          ),
                        ),
                      for (final m in chat.messages) _Bubble(message: m),
                      if (chat.sending) const _Thinking(),
                      if (chat.error != null) _Problem(text: chat.error!, onRetry: chat.canRetry ? () => ref.read(coachControllerProvider.notifier).retry() : null),
                    ],
                  ),
          ),
          if (hasKey)
            _Composer(
              controller: _question,
              enabled: !chat.sending && used < coachDailyLimit,
              showSuggestions: chat.messages.isEmpty,
              onSend: _send,
            ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});

  final CoachMessage message;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final mine = message.fromOwner;
    final text = SelectableText(message.text, style: TextStyle(color: mine ? c.onPrimary : c.ink, height: 1.45));
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.m),
      child: Align(
        alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.82),
          child: Semantics(
            label: mine ? 'You asked' : 'The coach said',
            child: mine
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l, vertical: AppSpacing.m),
                    decoration: BoxDecoration(
                      color: c.primary,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(6),
                      ),
                    ),
                    child: text,
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SoftCard(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l, vertical: AppSpacing.m), radius: 20, child: text),
                      if (message.looked.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(AppSpacing.s, AppSpacing.xs, AppSpacing.s, 0),
                          child: Text('Looked at: ${message.looked.join(' · ')}', style: TextStyle(color: c.muted, fontSize: 12)),
                        ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _Thinking extends StatelessWidget {
  const _Thinking();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: AppSpacing.m),
        child: Row(
          children: [
            const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2)),
            const SizedBox(width: AppSpacing.s),
            Text('The coach is thinking…', style: TextStyle(color: context.colors.muted)),
          ],
        ),
      );
}

class _Problem extends StatelessWidget {
  const _Problem({required this.text, required this.onRetry});

  final String text;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.m),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.m),
        decoration: BoxDecoration(color: c.badSurface, borderRadius: BorderRadius.circular(AppRadii.control)),
        child: Row(
          children: [
            Expanded(child: Text(text, style: TextStyle(color: c.bad))),
            if (onRetry != null) TextButton(onPressed: onRetry, child: Text('Try again', style: TextStyle(color: c.bad, fontWeight: FontWeight.w700))),
          ],
        ),
      ),
    );
  }
}

/// Suggested questions and the question box, pinned under the conversation.
class _Composer extends StatelessWidget {
  const _Composer({required this.controller, required this.enabled, required this.showSuggestions, required this.onSend});

  final TextEditingController controller;
  final bool enabled;
  final bool showSuggestions;
  final Future<void> Function([String? text]) onSend;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.l, AppSpacing.s, AppSpacing.l, AppSpacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showSuggestions)
            Wrap(
              spacing: AppSpacing.s,
              runSpacing: AppSpacing.s,
              children: [
                for (final s in coachSuggestions) ActionChip(label: Text(s), onPressed: enabled ? () => onSend(s) : null),
              ],
            ),
          if (showSuggestions) const SizedBox(height: AppSpacing.s),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  enabled: enabled,
                  minLines: 1,
                  maxLines: 4,
                  maxLength: 500,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => onSend(),
                  decoration: const InputDecoration(hintText: 'Ask the coach…', counterText: ''),
                ),
              ),
              const SizedBox(width: AppSpacing.s),
              IconButton.filled(
                onPressed: enabled ? () => onSend() : null,
                icon: const Icon(Icons.arrow_upward_rounded),
                tooltip: 'Send',
                style: IconButton.styleFrom(minimumSize: const Size(52, 52), backgroundColor: c.primary, foregroundColor: c.onPrimary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
