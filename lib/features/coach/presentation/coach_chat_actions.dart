import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/validation/capitalise_first_formatter.dart';
import '../../../core/widgets/confirm_delete.dart';
import '../../../core/widgets/done_bar.dart';
import '../../../core/widgets/spring_menu.dart';
import '../domain/coach_thread.dart';
import 'coach_avatar.dart';
import 'coach_chat_settings.dart';
import 'coach_chats.dart';

/// What can be done to a chat from the list or from inside it.
enum ChatAction { settings, pin, rename, delete }

/// Inside a chat its menu leads with the chat's own coach and personality.
const chatSettingsItem = SpringMenuItem(value: ChatAction.settings, icon: Icons.tune_rounded, label: 'Chat settings');

/// The chat's own actions, as a [SpringMenuButton] lists them.
List<SpringMenuItem<ChatAction>> chatMenuItems(CoachThread chat) => [
      SpringMenuItem(value: ChatAction.pin, icon: chat.pinned ? Icons.push_pin_outlined : Icons.push_pin_rounded, label: chat.pinned ? 'Unpin chat' : 'Pin chat'),
      const SpringMenuItem(value: ChatAction.rename, icon: Icons.edit_outlined, label: 'Rename chat'),
      const SpringMenuItem(value: ChatAction.delete, icon: Icons.delete_outline_rounded, label: 'Delete chat', destructive: true),
    ];

/// Does [action] to [chat]. Deleting asks first, offers Undo, and calls
/// [onDeleted] before the Undo shows, so a page about the chat can close.
Future<void> runChatAction(BuildContext context, WidgetRef ref, CoachThread chat, ChatAction action, {VoidCallback? onDeleted}) async {
  final chats = ref.read(coachChatsProvider.notifier);
  switch (action) {
    case ChatAction.settings:
      await showChatSettings(context, chat.id);
    case ChatAction.pin:
      await chats.pin(chat.id, !chat.pinned);
    case ChatAction.rename:
      final title = await showModalBottomSheet<String>(
        context: context,
        useRootNavigator: true,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => _RenameSheet(title: chat.title),
      );
      if (title != null) await chats.rename(chat.id, title);
    case ChatAction.delete:
      final n = chat.messages.length;
      final sure = await confirmDelete(
        context,
        title: 'Delete this chat?',
        message: 'The coach forgets its $n ${n == 1 ? 'message' : 'messages'}. Your entries, accounts and figures stay exactly as they are.',
      );
      if (!sure || !context.mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      final gone = await chats.delete(chat.id);
      onDeleted?.call();
      if (gone == null) return;
      showBar(messenger, 'Chat deleted', undo: () => chats.restore([gone]));
  }
}

/// The sheet a press and hold on a chat opens: its coach and name, then its
/// actions.
Future<void> showChatActions(BuildContext context, WidgetRef ref, CoachThread chat) async {
  HapticFeedback.mediumImpact();
  final idle = ref.read(coachIdleMotionProvider);
  final action = await showModalBottomSheet<ChatAction>(
    context: context,
    // Over the bottom bar, which would otherwise cover its last rows.
    useRootNavigator: true,
    useSafeArea: true,
    builder: (context) {
      final c = context.colors;
      return Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.s, 0, AppSpacing.s, AppSpacing.l),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              leading: CoachAvatar(face: chat.face, size: 36, idle: idle),
              title: Text(chat.title.isEmpty ? 'New chat' : chat.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
            for (final item in chatMenuItems(chat))
              ListTile(
                minTileHeight: 52,
                leading: Icon(item.icon, color: item.destructive ? c.bad : c.muted),
                title: Text(item.label, style: TextStyle(fontWeight: FontWeight.w600, color: item.destructive ? c.bad : null)),
                onTap: () => Navigator.of(context).pop(item.value),
              ),
          ],
        ),
      );
    },
  );
  if (action != null && context.mounted) await runChatAction(context, ref, chat, action);
}

class _RenameSheet extends StatefulWidget {
  const _RenameSheet({required this.title});

  final String title;

  @override
  State<_RenameSheet> createState() => _RenameSheetState();
}

class _RenameSheetState extends State<_RenameSheet> {
  late final _name = TextEditingController(text: widget.title);
  final _form = GlobalKey<FormState>();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _save() {
    if (_form.currentState!.validate()) Navigator.of(context).pop(_name.text.trim());
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(AppSpacing.l, 0, AppSpacing.l, AppSpacing.l + MediaQuery.viewInsetsOf(context).bottom),
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Rename chat', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: AppSpacing.m),
              TextFormField(
                controller: _name,
                maxLength: chatNameLength,
                textCapitalization: TextCapitalization.sentences,
                inputFormatters: const [CapitaliseFirstFormatter()],
                textInputAction: TextInputAction.done,
                // Checked on Save, then again with each key once it has said
                // something, so the message clears as soon as it is fixed.
                autovalidateMode: AutovalidateMode.onUserInteractionIfError,
                validator: (v) => (v ?? '').trim().isEmpty ? 'Give the chat a name.' : null,
                onFieldSubmitted: (_) => _save(),
                decoration: const InputDecoration(labelText: 'Chat name', hintText: 'e.g. Laptop plan'),
              ),
              const SizedBox(height: AppSpacing.s),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                  const SizedBox(width: AppSpacing.s),
                  FilledButton(onPressed: _save, child: const Text('Save')),
                ],
              ),
            ],
          ),
        ),
      );
}
