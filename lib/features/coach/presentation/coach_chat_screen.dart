import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../../core/dates/dates.dart';
import '../../../core/money/money.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/validation/capitalise_first_formatter.dart';
import '../../../core/widgets/soft.dart';
import '../../../core/widgets/spring_in.dart';
import '../../../core/widgets/spring_menu.dart';
import '../domain/coach_client.dart';
import '../domain/coach_prompt.dart';
import '../domain/coach_proposals.dart';
import '../domain/coach_settings.dart';
import 'coach_attention.dart';
import 'coach_avatar.dart';
import 'coach_chat_actions.dart';
import 'coach_chat_settings.dart';
import 'coach_chats.dart';
import 'coach_controller.dart';
import 'coach_reply_text.dart';
import 'coach_providers.dart';

/// One chat with the coach, on a page of its own over the bottom bar: its
/// coach at the top, the conversation, and the question box at the bottom.
/// Answers come from Anthropic using the user's own key. A new chat left
/// before anything is asked in it is not kept.
class CoachChatScreen extends ConsumerStatefulWidget {
  const CoachChatScreen({super.key, required this.chat});

  final int chat;

  @override
  ConsumerState<CoachChatScreen> createState() => _CoachChatScreenState();
}

class _CoachChatScreenState extends ConsumerState<CoachChatScreen> {
  final _question = TextEditingController();
  final _scroll = ScrollController();
  final _typing = FocusNode();

  /// What the coach at the top notices: the chat scrolling, and the user
  /// typing, when it looks down at the question box.
  final _attention = CoachAttention();

  /// Read on arrival, as the page cannot reach it once it is going.
  late final CoachChatsController _chats;

  /// Whether the chat has been on screen; until then its messages are simply
  /// there, and after it each one springs in as it comes into view.
  var _shown = false;

  /// The messages on screen, by index, so a new reply can be measured.
  final _rows = <int, BuildContext>{};

  @override
  void initState() {
    super.initState();
    _chats = ref.read(coachChatsProvider.notifier);
    WidgetsBinding.instance.addPostFrameCallback((_) => _shown = true);
    _question.addListener(_watchTyping);
    _typing.addListener(_watchTyping);
  }

  @override
  void dispose() {
    _chats.discardIfEmpty(widget.chat);
    _question.dispose();
    _typing.dispose();
    _attention.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// Brings the newest message into view. A reply taller than the chat stops
  /// with its first line under the header, to be read down from there;
  /// anything shorter lands at the bottom.
  Future<void> _showNewest() async {
    if (!mounted || !_scroll.hasClients) return;
    final messages = ref.read(coachControllerProvider(widget.chat)).messages;
    final reply = messages.isNotEmpty && !messages.last.fromUser;
    final newest = messages.length - 1;
    if (reply && _rows[newest] == null) {
      // Scrolled too far up for it to be built yet: down first, then measure.
      await _scroll.animateTo(0, duration: AppMotion.fast, curve: AppMotion.ease);
      if (!mounted || !_scroll.hasClients) return;
    }
    final row = reply ? _rows[newest] : null;
    final to = row != null && row.mounted ? _offsetToStartOf(row) : 0.0;
    await _scroll.animateTo(to, duration: AppMotion.fast, curve: AppMotion.ease);
  }

  /// The scroll offset that puts [row]'s top just under the header, or 0
  /// when all of it fits. The list is laid out from the bottom, so a larger
  /// offset moves its rows down the screen by as much.
  double _offsetToStartOf(BuildContext row) {
    final box = row.findRenderObject()! as RenderBox;
    final viewport = Scrollable.of(row).context.findRenderObject()! as RenderBox;
    final topAtBottom = box.localToGlobal(Offset.zero).dy - _scroll.offset;
    // The row's own top spacing keeps the bubble off the header.
    return math.max(0, viewport.localToGlobal(Offset.zero).dy - topAtBottom);
  }

  void _watchTyping() =>
      _attention.lookAt(_typing.hasFocus && _question.text.isNotEmpty ? const Offset(-0.4, 2.2) : Offset.zero);

  Future<void> _send([String? text]) async {
    final question = text ?? _question.text;
    if (question.trim().isEmpty) return;
    _question.clear();
    await ref.read(coachControllerProvider(widget.chat).notifier).ask(question);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final id = widget.chat;
    final chat = ref.watch(coachControllerProvider(id));
    final thread = ref.watch(coachChatsProvider).byId(id);
    final today = ref.watch(todayProvider);
    final defaults = ref.watch(coachSettingsProvider).value ?? const CoachSettings();
    final remember = defaults.remember;
    final settings = CoachSettings(face: thread?.face ?? defaults.face, personality: thread?.personality ?? defaults.personality);
    final mood = ref.watch(coachMoodProvider(id));
    final idle = ref.watch(coachIdleMotionProvider);
    final used = ref.watch(coachUsedTodayProvider).value ?? 0;
    // Watched so the figures the coach is given stay loaded; the controller
    // only reads them, and an unwatched provider never loads its inputs.
    ref.watch(coachDataProvider);
    // To each new message as the conversation grows.
    ref.listen(coachChatsProvider.select((c) => c.byId(id)?.messages.length ?? 0), (before, now) {
      if (now > (before ?? 0)) WidgetsBinding.instance.addPostFrameCallback((_) => _showNewest());
    });
    // A chat opens at its newest message: the list is laid out from the
    // bottom, so it is there from the first frame, not scrolled to after.
    // The greeting of an empty chat still sits at the top.
    final fromBottom = chat.messages.isNotEmpty;

    return PopScope(
      // Gone from the list the moment it is left, not when the page is
      // finally taken down after its exit.
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _chats.discardIfEmpty(id);
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.xs, AppSpacing.s, AppSpacing.l, 0),
                child: SizedBox(
                  height: 48,
                  child: Row(
                    children: [
                      const BackButton(),
                      Expanded(
                        child: Semantics(
                          button: true,
                          label: "This chat's coach, ${settings.face.label}, ${settings.personality.label}. Change",
                          excludeSemantics: true,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(AppRadii.control),
                            onTap: () => showChatSettings(context, id),
                            child: Row(
                              children: [
                                CoachAvatar(face: settings.face, mood: mood, size: 40, idle: idle, attention: _attention),
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
                      // Nothing to pin, rename or delete until something is said.
                      if (thread != null && thread.messages.isNotEmpty)
                        SpringMenuButton<ChatAction>(
                          items: [chatSettingsItem, ...chatMenuItems(thread)],
                          onSelected: (a) => runChatAction(context, ref, thread, a, onDeleted: () => Navigator.of(context).pop()),
                        ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: ScrollAttention(
                  attention: _attention,
                  reach: 2,
                  child: ListView(
                      controller: _scroll,
                      reverse: fromBottom,
                      // Messages are built only as they come into view, so
                      // each springs in where it can be seen.
                      scrollCacheExtent: const ScrollCacheExtent.pixels(0),
                      padding: const EdgeInsets.fromLTRB(AppSpacing.l, AppSpacing.m, AppSpacing.l, AppSpacing.l),
                      children: _topDown(fromBottom, [
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
                          _Row(
                            key: ValueKey(('message', i)),
                            index: i,
                            rows: _rows,
                            child: m.note
                                ? SpringIn(animate: _shown, alignment: Alignment.center, child: _Note(m.text))
                                : SpringIn(
                                    animate: _shown,
                                    alignment: m.fromUser ? Alignment.bottomRight : Alignment.bottomLeft,
                                    child: _Bubble(message: m),
                                  ),
                          ),
                          for (final (j, card) in m.cards.indexed)
                            _ProposalCard(
                              card: card,
                              onConfirm: () => ref.read(coachControllerProvider(id).notifier).confirm(i, j),
                              onDecline: () => ref.read(coachControllerProvider(id).notifier).decline(i, j),
                              onUndo: () => ref.read(coachControllerProvider(id).notifier).undo(i, j),
                            ),
                        ],
                        if (chat.sending) _Thinking(reading: chat.reading),
                        if (chat.error != null) _Problem(text: chat.error!, onRetry: chat.canRetry ? () => ref.read(coachControllerProvider(id).notifier).retry() : null),
                      ]),
                  ),
                ),
              ),
              _Composer(
                controller: _question,
                focusNode: _typing,
                enabled: !chat.sending && used < coachDailyLimit,
                showSuggestions: chat.messages.isEmpty,
                onSend: _send,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One message on screen, kept in [rows] under its [index] while it is
/// built, so the chat can measure where it sits.
class _Row extends StatefulWidget {
  const _Row({super.key, required this.index, required this.rows, required this.child});

  final int index;
  final Map<int, BuildContext> rows;
  final Widget child;

  @override
  State<_Row> createState() => _RowState();
}

class _RowState extends State<_Row> {
  @override
  void dispose() {
    if (widget.rows[widget.index] == context) widget.rows.remove(widget.index);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    widget.rows[widget.index] = context;
    return widget.child;
  }
}

/// The chat's rows, oldest first, in the order the list lays them out: a
/// list laid out from the bottom takes its newest row first.
List<Widget> _topDown(bool fromBottom, List<Widget> rows) => fromBottom ? rows.reversed.toList() : rows;

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

/// A line in the chat said by nobody, such as a change of personality.
class _Note extends StatelessWidget {
  const _Note(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: AppSpacing.m),
        child: Center(child: Text(text, textAlign: TextAlign.center, style: TextStyle(color: context.colors.muted, fontSize: 12.5, fontWeight: FontWeight.w600))),
      );
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

/// One message. Both sides have a tail at the bottom corner nearest the
/// speaker; the coach is named at the top of the chat, so a reply needs no
/// face beside it and takes the full width.
class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});

  final CoachMessage message;

  static const _round = Radius.circular(20);
  static const _tail = Radius.circular(6);

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final mine = message.fromUser;
    final style = TextStyle(color: mine ? c.onPrimary : c.ink, height: 1.45);
    // The user's words as typed; the coach's as it means them read.
    final text = mine ? SelectableText(message.text, style: style) : CoachReplyText(message.text, style: style);
    const padding = EdgeInsets.symmetric(horizontal: AppSpacing.l, vertical: AppSpacing.m);
    final bubble = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.82),
      child: Semantics(
        label: mine ? 'You asked' : 'The coach said',
        child: mine
            ? Container(
                padding: padding,
                decoration: BoxDecoration(
                  color: c.primary,
                  borderRadius: const BorderRadius.only(topLeft: _round, topRight: _round, bottomLeft: _round, bottomRight: _tail),
                ),
                child: text,
              )
            : SoftCard(
                padding: padding,
                borderRadius: const BorderRadius.only(topLeft: _round, topRight: _round, bottomLeft: _tail, bottomRight: _round),
                child: message.looked.isEmpty
                    ? text
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          text,
                          // What the reply was drawn from belongs to it, so it
                          // is the bubble's footer rather than a line between
                          // messages.
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(top: AppSpacing.s),
                            padding: const EdgeInsets.only(top: AppSpacing.s),
                            decoration: BoxDecoration(border: Border(top: BorderSide(color: c.line, width: 0.5))),
                            child: Text('Looked at: ${message.looked.join(' · ')}', style: TextStyle(color: c.muted, fontSize: 12)),
                          ),
                        ],
                      ),
              ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.m),
      child: Align(alignment: mine ? Alignment.centerRight : Alignment.centerLeft, child: bubble),
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
      padding: const EdgeInsets.only(top: AppSpacing.s),
      child: Align(
        alignment: Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.82),
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
    // No "…": the dots after the words are its ellipsis.
    final status = reading == null
        ? 'Thinking'
        : reading.startsWith('A suggestion')
            ? 'Writing up a suggestion'
            // As the reply's own "Looked at:" line will say, label untouched.
            : 'Looking at: $reading';
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.m),
      child: Semantics(
        liveRegion: true,
        label: 'The coach is ${status[0].toLowerCase()}${status.substring(1)}',
        excludeSemantics: true,
        child: Row(
          children: [
            Flexible(
              child: SoftCard(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l, vertical: AppSpacing.m + 2),
              borderRadius: const BorderRadius.only(topLeft: _Bubble._round, topRight: _Bubble._round, bottomLeft: _Bubble._tail, bottomRight: _Bubble._round),
              // The bubble springs to the width of each new status.
              child: AnimatedSize(
                duration: AppMotion.enter,
                curve: Curves.easeOutBack,
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(child: Text(status, overflow: TextOverflow.ellipsis, style: TextStyle(color: c.muted, fontSize: 13.5))),
                    const SizedBox(width: AppSpacing.s),
                    AnimatedBuilder(
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
                  ],
                ),
              ),
            ),
            ),
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
  const _Composer({required this.controller, required this.focusNode, required this.enabled, required this.showSuggestions, required this.onSend});

  final TextEditingController controller;
  final FocusNode focusNode;
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
                  key: const ValueKey('coach-question'),
                  controller: controller,
                  focusNode: focusNode,
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
