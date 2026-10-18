import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/database_provider.dart';
import '../../../core/dates/dates.dart';
import '../../../core/money/money.dart';
import '../../../core/navigation/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/validation/capitalise_first_formatter.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/soft.dart';
import '../../../core/widgets/spring_in.dart';
import '../domain/coach_client.dart';
import '../domain/coach_prompt.dart';
import '../domain/coach_proposals.dart';
import '../domain/coach_settings.dart';
import 'coach_avatar.dart';
import 'coach_controller.dart';
import 'coach_picker.dart';
import 'coach_providers.dart';

/// Ask about your money. Answers come from Anthropic using the user's own
/// key; the question box stays pinned to the bottom of the screen.
class CoachScreen extends ConsumerStatefulWidget {
  const CoachScreen({super.key});

  @override
  ConsumerState<CoachScreen> createState() => _CoachScreenState();
}

class _CoachScreenState extends ConsumerState<CoachScreen> {
  final _question = TextEditingController();
  final _scroll = ScrollController();

  /// How many messages were already there when the tab opened.
  late final _openedWith = ref.read(coachControllerProvider).messages.length;

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
    final today = ref.watch(todayProvider);
    final settings = ref.watch(coachSettingsProvider).value ?? const CoachSettings();
    final remember = settings.remember;
    final mood = ref.watch(coachMoodProvider);
    final idle = ref.watch(coachIdleMotionProvider);
    // What was on screen when it opened, or came back from memory, is already
    // in place; only what is said from here springs in.
    final settledCount = math.max(_openedWith, ref.read(coachControllerProvider.notifier).settled);
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
                  if (!hasKey)
                    Text('Coach', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5))
                  else
                    Expanded(
                      child: Semantics(
                        button: true,
                        label: 'Your coach, ${settings.face.label}, ${settings.personality.label}. Switch coach',
                        excludeSemantics: true,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(AppRadii.control),
                          onTap: () => showCoachPicker(context),
                          child: Row(
                            children: [
                              CoachAvatar(face: settings.face, mood: mood, size: 40, idle: idle),
                              const SizedBox(width: AppSpacing.s),
                              Flexible(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Flexible(
                                          child: Text(
                                            settings.face.label,
                                            overflow: TextOverflow.ellipsis,
                                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.4),
                                          ),
                                        ),
                                        Icon(Icons.expand_more_rounded, size: 20, color: c.muted),
                                      ],
                                    ),
                                    Text(chat.sending ? 'thinking…' : settings.personality.label, overflow: TextOverflow.ellipsis, style: TextStyle(color: c.muted, fontSize: 12.5)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(width: AppSpacing.s),
                  if (!hasKey) const Spacer(),
                  if (hasKey)
                    // Capped, so the coach's name keeps the spare width and the
                    // pill and copy button stay at the edge; it shortens with
                    // an ellipsis at large text sizes.
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 120),
                      child: Semantics(
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
                        Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.xxl),
                          child: Column(
                            children: [
                              CoachAvatar(face: settings.face, mood: mood, size: 112, idle: idle, onTap: () {}),
                              const SizedBox(height: AppSpacing.l),
                              Text("Hi, I'm ${settings.face.label}.", style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                settings.face == CoachFace.bajety
                                    ? "What's a bajety, is that a new Verity? No lah. I look up your weeks, months, accounts and plan to "
                                        'answer, and I always check with you before changing a thing.'
                                    : 'I look up your weeks, months, accounts and plan to answer, and I always check with you before '
                                        'changing a thing.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: c.muted, height: 1.4),
                              ),
                              const SizedBox(height: AppSpacing.s),
                              Text('Each question sends only what it looked up to Anthropic with your key.',
                                  textAlign: TextAlign.center, style: TextStyle(color: c.muted, fontSize: 12.5)),
                            ],
                          ),
                        ),
                      if (chat.messages.isNotEmpty && remember)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.lock_outline_rounded, size: 14, color: c.muted),
                              const SizedBox(width: AppSpacing.xs),
                              Flexible(child: Text('Remembered on this phone only', textAlign: TextAlign.center, style: TextStyle(color: c.muted, fontSize: 12))),
                            ],
                          ),
                        ),
                      for (final (i, m) in chat.messages.indexed) ...[
                        if (_dayLabel(chat.messages, i, today) case final label?) _DayLabel(label),
                        SpringIn(
                          key: ValueKey(('message', i)),
                          animate: i >= settledCount,
                          alignment: m.fromUser ? Alignment.bottomRight : Alignment.bottomLeft,
                          child: _Bubble(
                            message: m,
                            // A run of replies shows its face once, beside the last.
                            face: m.fromUser || (i + 1 < chat.messages.length && !chat.messages[i + 1].fromUser) ? null : (m.face ?? settings.face),
                          ),
                        ),
                        for (final (j, card) in m.cards.indexed)
                          _ProposalCard(
                            card: card,
                            onConfirm: () => ref.read(coachControllerProvider.notifier).confirm(i, j),
                            onDecline: () => ref.read(coachControllerProvider.notifier).decline(i, j),
                            onUndo: () => ref.read(coachControllerProvider.notifier).undo(i, j),
                          ),
                      ],
                      if (chat.sending) _Thinking(reading: chat.reading),
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

/// "Today", "Yesterday" or a day such as "Sat 17/10" above the first
/// message of each day, or null when the day has not changed.
String? _dayLabel(List<CoachMessage> messages, int i, DateTime today) {
  final at = messages[i].sentAt;
  if (at == null) return null;
  final day = DateTime.utc(at.year, at.month, at.day);
  final before = i == 0 ? null : messages[i - 1].sentAt;
  if (before != null && DateTime.utc(before.year, before.month, before.day) == day) return null;
  final gap = today.difference(day).inDays;
  return gap == 0 ? 'Today' : gap == 1 ? 'Yesterday' : '${Dates.weekday(day)} ${Dates.short(day)}';
}

class _DayLabel extends StatelessWidget {
  const _DayLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: AppSpacing.l, bottom: AppSpacing.xs),
        child: Center(child: Text(label, style: TextStyle(color: context.colors.muted, fontSize: 12, fontWeight: FontWeight.w700))),
      );
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, this.face});

  final CoachMessage message;

  /// The coach who gave a reply, shown beside it; null for none.
  final CoachFace? face;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final mine = message.fromUser;
    final text = SelectableText(message.text, style: TextStyle(color: mine ? c.onPrimary : c.ink, height: 1.45));
    final bubble = ConstrainedBox(
          constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * (mine ? 0.82 : 0.72)),
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
        );
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.m),
      child: mine
          ? Align(alignment: Alignment.centerRight, child: bubble)
          : Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // The space stays when the face is not shown, so a run of
                // replies lines up.
                SizedBox(width: 30, child: face == null ? null : CoachAvatar(face: face!, size: 30, animate: false)),
                const SizedBox(width: AppSpacing.s),
                Flexible(child: bubble),
              ],
            ),
    );
  }
}

/// A change the coach suggested: what it would do, and the buttons that
/// decide it. Nothing is written until Confirm is tapped.
class _ProposalCard extends StatelessWidget {
  const _ProposalCard({required this.card, required this.onConfirm, required this.onDecline, required this.onUndo});

  final CoachCard card;
  final VoidCallback onConfirm, onDecline, onUndo;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final p = card.proposal;
    final done = card.state == CardState.done;
    final settled = card.state == CardState.declined || card.state == CardState.undone || card.state == CardState.outdated;
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(done ? '✓ ${card.outcome}' : card.outcome, style: TextStyle(color: done ? c.good : c.muted, fontWeight: FontWeight.w700, fontSize: 13)),
        const SizedBox(height: AppSpacing.xs),
        Text(Money.format(p.amount), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, fontFeatures: [FontFeature.tabularFigures()])),
        for (final (label, value) in p.rows)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Row(
              children: [
                Text(label, style: TextStyle(color: c.muted)),
                const SizedBox(width: AppSpacing.m),
                Expanded(child: Text(value, textAlign: TextAlign.end, overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
        if (card.state == CardState.waiting) ...[
          const SizedBox(height: AppSpacing.m),
          Row(
            children: [
              Expanded(child: OutlinedButton(onPressed: onDecline, style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)), child: const Text('Not now'))),
              const SizedBox(width: AppSpacing.s),
              Expanded(child: FilledButton(onPressed: onConfirm, style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)), child: Text(card.action))),
            ],
          ),
        ] else if (card.canUndo)
          Align(alignment: Alignment.centerRight, child: TextButton(onPressed: onUndo, child: const Text('Undo'))),
      ],
    );
    return Padding(
      // Lined up with the reply bubbles, past the coach's face.
      padding: const EdgeInsets.only(top: AppSpacing.s, left: 30 + AppSpacing.s),
      child: Align(
        alignment: Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.72),
          child: AnimatedOpacity(
            opacity: settled ? 0.6 : 1,
            duration: AppMotion.fast,
            child: done
                ? Container(
                    padding: const EdgeInsets.all(AppSpacing.l),
                    decoration: BoxDecoration(color: c.goodSurface, borderRadius: BorderRadius.circular(20)),
                    child: body,
                  )
                : SoftCard(padding: const EdgeInsets.all(AppSpacing.l), radius: 20, child: body),
          ),
        ),
      ),
    );
  }
}

/// The coach at work: three dots bobbing in a reply bubble, and what it is
/// reading once it starts looking things up.
class _Thinking extends StatefulWidget {
  const _Thinking({required this.reading});

  final String? reading;

  @override
  State<_Thinking> createState() => _ThinkingState();
}

class _ThinkingState extends State<_Thinking> with SingleTickerProviderStateMixin {
  late final _bob = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _bob.stop();
    } else if (!_bob.isAnimating) {
      _bob.repeat();
    }
  }

  @override
  void dispose() {
    _bob.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final reading = widget.reading;
    final status = reading == null
        ? 'Thinking…'
        : reading.startsWith('A suggestion')
            ? 'Writing up a suggestion…'
            // As the reply's own "Looked at:" line will say, label untouched.
            : 'Looking at: $reading…';
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.m, left: 30 + AppSpacing.s),
      child: Semantics(
        liveRegion: true,
        label: 'The coach is ${status[0].toLowerCase()}${status.substring(1)}',
        excludeSemantics: true,
        child: Row(
          children: [
            SoftCard(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l, vertical: AppSpacing.m + 2),
              radius: 20,
              child: AnimatedBuilder(
                animation: _bob,
                builder: (context, _) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < 3; i++)
                      Padding(
                        padding: EdgeInsets.only(left: i == 0 ? 0 : 5),
                        child: Transform.translate(
                          // Each dot rises in turn, a third of a beat apart.
                          offset: Offset(0, -4 * math.max(0.0, math.sin((_bob.value - i * 0.16) * math.pi * 2))),
                          child: Container(width: 7, height: 7, decoration: BoxDecoration(color: c.muted, shape: BoxShape.circle)),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.s),
            Flexible(child: Text(status, overflow: TextOverflow.ellipsis, style: TextStyle(color: c.muted, fontSize: 13))),
          ],
        ),
      ),
    );
  }
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
                  inputFormatters: const [CapitaliseFirstFormatter()],
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
