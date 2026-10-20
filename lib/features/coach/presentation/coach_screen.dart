import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/database_provider.dart';
import '../../../core/dates/dates.dart';
import '../../../core/navigation/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/rise_in.dart';
import '../../../core/widgets/soft.dart';
import '../../../core/widgets/spring_in.dart';
import '../../../core/widgets/spring_menu.dart';
import '../../../core/widgets/under_bar.dart';
import '../domain/coach_client.dart';
import '../domain/coach_settings.dart';
import '../domain/coach_thread.dart';
import 'coach_attention.dart';
import 'coach_chat_actions.dart';
import 'coach_avatar.dart';
import 'coach_chats.dart';
import 'coach_providers.dart';

/// When a chat last had something said in it, as a chat list says it:
/// `14:05` today, `Yesterday`, a weekday within the week, then `17/10`, and
/// the full date once it is another year.
String chatTimeLabel(DateTime at, DateTime today) {
  final day = DateTime.utc(at.year, at.month, at.day);
  final gap = today.difference(day).inDays;
  if (gap <= 0) return Dates.time(at);
  if (gap == 1) return 'Yesterday';
  if (gap < 7) return Dates.weekday(at);
  return at.year == today.year ? Dates.short(at) : Dates.full(at);
}

/// The Coach tab: every chat with the coach, pinned ones first, then the
/// most recent. A chat opens on its own page; the round button above the
/// log button starts a new one.
class CoachScreen extends ConsumerStatefulWidget {
  const CoachScreen({super.key});

  @override
  ConsumerState<CoachScreen> createState() => _CoachScreenState();
}

class _CoachScreenState extends ConsumerState<CoachScreen> {
  /// Shared by every face in the list, so they all notice the scrolling.
  final _attention = CoachAttention();

  /// When each chat shown last had something said, so one that moves up
  /// with something new springs into its place.
  Map<int, DateTime>? _shown;

  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _attention.dispose();
    _search.dispose();
    super.dispose();
  }

  /// The chats whose name or messages hold every word searched for.
  List<CoachThread> _found(List<CoachThread> listed) {
    final words = _search.text.toLowerCase().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return listed;
    return [
      for (final t in listed)
        if (words.every((w) => t.title.toLowerCase().contains(w) || t.messages.any((m) => m.text.toLowerCase().contains(w)))) t,
    ];
  }

  Future<void> _start() async {
    final id = await ref.read(coachChatsProvider.notifier).start();
    if (mounted) await context.push(Routes.coachChat(id));
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
    final chats = ref.watch(coachChatsProvider);
    final listed = chats.listed;
    final found = _found(listed);
    final today = ref.watch(todayProvider);
    final remember = (ref.watch(coachSettingsProvider).value ?? const CoachSettings()).remember;
    final idle = ref.watch(coachIdleMotionProvider);
    final used = ref.watch(coachUsedTodayProvider).value ?? 0;
    final shown = _shown;
    _shown = {for (final t in listed) t.id: t.lastAt};

    return SafeArea(
      bottom: false,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.l, AppSpacing.s, AppSpacing.l, 0),
                child: SizedBox(
                  height: 48,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Coach',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5),
                        ),
                      ),
                      if (hasKey)
                        // Capped, so the title keeps its room; it shortens with
                        // an ellipsis at large text sizes.
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 120),
                          child: Semantics(
                            label: '$used of $coachDailyLimit questions used today',
                            excludeSemantics: true,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.xs + 1),
                              decoration: BoxDecoration(color: c.primarySoft, borderRadius: BorderRadius.circular(AppRadii.pill)),
                              child: Text('${coachDailyLimit - used} left today', overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ),
                      SpringMenuButton<_ListAction>(
                        items: const [
                          SpringMenuItem(value: _ListAction.copySummary, icon: Icons.copy_rounded, label: "Copy this week's summary"),
                          SpringMenuItem(value: _ListAction.settings, icon: Icons.tune_rounded, label: 'Coach settings'),
                        ],
                        onSelected: (a) => switch (a) {
                          _ListAction.copySummary => _copySummary(),
                          _ListAction.settings => context.push(Routes.coachKey),
                        },
                      ),
                    ],
                  ),
                ),
              ),
              if (hasKey && listed.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.l, AppSpacing.s, AppSpacing.l, 0),
                  child: TextField(
                    key: const ValueKey('search-chats'),
                    controller: _search,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Search chats',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _search.text.isEmpty ? null : IconButton(onPressed: _search.clear, icon: const Icon(Icons.close_rounded), tooltip: 'Clear the search'),
                    ),
                  ),
                ),
              Expanded(
                child: !hasKey
                    ? SafeArea(
                        top: false,
                        child: EmptyState(
                          icon: Icons.forum_outlined,
                          title: 'Ask about your money',
                          message: 'The coach looks up your own figures to answer, using your own Anthropic API key.',
                          actionLabel: 'Add your key',
                          onAction: () => context.push(Routes.coachKey),
                          secondaryLabel: "Copy this week's summary",
                          onSecondary: _copySummary,
                        ),
                      )
                    : !chats.loaded
                        // Read from the phone in a moment; nothing to show meanwhile.
                        ? const SizedBox.shrink()
                        : listed.isEmpty
                            ? SafeArea(
                                top: false,
                                child: EmptyState(
                                  icon: Icons.forum_outlined,
                                  title: 'No chats yet',
                                  message: 'Ask about your week, a bill or a goal. Each chat keeps its own coach and its own memory.',
                                  actionLabel: 'Start a chat',
                                  onAction: _start,
                                ),
                              )
                            : ScrollAttention(
                                attention: _attention,
                                child: ListView(
                                  padding: EdgeInsets.fromLTRB(AppSpacing.s, AppSpacing.s, AppSpacing.s, underBar(context) + _newChatSize + AppSpacing.m),
                                  children: [
                                    if (found.isEmpty)
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l, vertical: AppSpacing.xxxl),
                                        child: Text('No chats mention “${_search.text.trim()}”.', textAlign: TextAlign.center, style: TextStyle(color: c.muted)),
                                      ),
                                    for (final t in found)
                                      SpringIn(
                                        // A new key when something new is said, so it springs in again.
                                        key: ValueKey(('chat', t.id, t.lastAt)),
                                        animate: shown != null && shown[t.id] != t.lastAt,
                                        alignment: Alignment.topCenter,
                                        child: _ChatRow(
                                          key: ValueKey('chat-${t.id}'),
                                          thread: t,
                                          today: today,
                                          idle: idle,
                                          attention: _attention,
                                          onTap: () => context.push(Routes.coachChat(t.id)),
                                          onLongPress: () => showChatActions(context, ref, t),
                                        ),
                                      ),
                                    if (remember)
                                      Padding(
                                        padding: const EdgeInsets.only(top: AppSpacing.l),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.lock_outline_rounded, size: 14, color: c.muted),
                                            const SizedBox(width: AppSpacing.xs),
                                            Flexible(child: Text('Remembered on this phone only', style: TextStyle(color: c.muted, fontSize: 12))),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
              ),
            ],
          ),
          if (hasKey)
            Positioned(
              // Centred over the log button below it, the lighter of the two.
              right: AppSpacing.m + (_logButtonSize - _newChatSize) / 2,
              bottom: MediaQuery.paddingOf(context).bottom + AppSpacing.m,
              child: SpringIn(
                key: ValueKey(ref.watch(screenEntryProvider)),
                animate: true,
                alignment: Alignment.center,
                child: SoftButton(
                  key: const ValueKey('new-chat'),
                  semanticLabel: 'New chat',
                  radius: AppRadii.pill,
                  onTap: _start,
                  child: SizedBox.square(dimension: _newChatSize, child: Icon(Icons.add_comment_rounded, size: 24, color: c.primary)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

enum _ListAction { copySummary, settings }

const _newChatSize = 52.0;

/// The log button's size in the bottom bar, which the new chat button sits
/// centred above.
const _logButtonSize = 64.0;

/// One chat in the list: its coach, name, when it was last used and what
/// was said last.
class _ChatRow extends StatelessWidget {
  const _ChatRow({super.key, required this.thread, required this.today, required this.idle, required this.attention, required this.onTap, required this.onLongPress});

  final CoachThread thread;
  final DateTime today;
  final bool idle;
  final CoachAttention attention;
  final VoidCallback onTap;

  /// Opens the chat's actions: pin, rename and delete.
  final VoidCallback onLongPress;

  String get _preview {
    final last = thread.messages.last;
    return last.fromUser ? 'You: ${last.text}' : last.text;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final when = chatTimeLabel(thread.lastAt, today);
    final title = thread.title.isEmpty ? 'New chat' : thread.title;
    final preview = _preview.replaceAll('\n', ' ');
    return Semantics(
      button: true,
      label: '$title${thread.pinned ? ', pinned' : ''}, $when. $preview',
      onLongPressHint: 'pin, rename or delete',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(AppRadii.control),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s, vertical: AppSpacing.s + 2),
          child: Row(
            children: [
              CoachAvatar(face: thread.face, size: 48, idle: idle, attention: attention),
              const SizedBox(width: AppSpacing.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700))),
                        const SizedBox(width: AppSpacing.s),
                        Text(when, style: TextStyle(color: c.muted, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Expanded(child: Text(preview, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: c.muted, fontSize: 13.5))),
                        if (thread.pinned) ...[
                          const SizedBox(width: AppSpacing.s),
                          Icon(Icons.push_pin_rounded, size: 15, color: c.muted),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
