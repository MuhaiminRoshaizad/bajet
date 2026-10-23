import '../../../core/widgets/app_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/done_bar.dart';
import '../../coach/domain/coach_settings.dart';
import '../../coach/presentation/coach_providers.dart';

/// Where the user types what the coach should call them, in setup and in
/// Settings. A name is optional, so nothing typed is never an error.
class UserNameField extends StatelessWidget {
  const UserNameField({super.key, required this.controller, this.onSubmitted, this.onChanged});

  final TextEditingController controller;
  final VoidCallback? onSubmitted;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) => TextField(
        key: const ValueKey('user-name'),
        controller: controller,
        autofillHints: null,
        maxLength: userNameLength,
        keyboardType: TextInputType.name,
        // A name has no line breaks.
        inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'[\n\r\t]'))],
        textInputAction: TextInputAction.done,
        onChanged: onChanged,
        onSubmitted: (_) => onSubmitted?.call(),
        decoration: const InputDecoration(labelText: 'Your name', hintText: 'e.g. Sara'),
      );
}

/// Changes or clears the name the coach uses.
Future<void> showUserNameSheet(BuildContext context, String? current) => showAppSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _UserNameSheet(current: current),
    );

class _UserNameSheet extends ConsumerStatefulWidget {
  const _UserNameSheet({required this.current});

  final String? current;

  @override
  ConsumerState<_UserNameSheet> createState() => _UserNameSheetState();
}

class _UserNameSheetState extends ConsumerState<_UserNameSheet> {
  late final _name = TextEditingController(text: widget.current ?? '');

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    final repo = ref.read(coachSettingsRepositoryProvider);
    final name = _name.text.trim();
    await repo.saveUserName(name);
    if (mounted) Navigator.of(context).pop();
    showBar(messenger, name.isEmpty ? 'Name cleared. The coach uses no name.' : 'Saved. The coach will call you $name', undo: () => repo.saveUserName(widget.current ?? ''));
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl + MediaQuery.viewInsetsOf(context).bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Your name', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: AppSpacing.xs),
            const Text('What the coach calls you. Leave it empty and it uses no name.'),
            const SizedBox(height: AppSpacing.l),
            UserNameField(controller: _name, onSubmitted: _save),
            const SizedBox(height: AppSpacing.l),
            FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
              child: const Text('Save'),
            ),
          ],
        ),
      );
}
