import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/validation/capitalise_first_formatter.dart';
import '../../coach/domain/coach_settings.dart';
import '../../coach/presentation/coach_providers.dart';

/// Where the user types what the coach should call them, in setup and in
/// Settings. A name is optional, so nothing typed is never an error.
class UserNameField extends StatelessWidget {
  const UserNameField({super.key, required this.controller, this.autofocus = false, this.onSubmitted, this.onChanged});

  final TextEditingController controller;
  final bool autofocus;
  final VoidCallback? onSubmitted;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) => TextField(
        key: const ValueKey('user-name'),
        controller: controller,
        autofocus: autofocus,
        maxLength: userNameLength,
        textCapitalization: TextCapitalization.words,
        keyboardType: TextInputType.name,
        autofillHints: const [AutofillHints.givenName],
        // A name has no line breaks; the first letter is capitalised for
        // keyboards that ignore textCapitalization.
        inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'[\n\r\t]')), const CapitaliseFirstFormatter()],
        textInputAction: TextInputAction.done,
        onChanged: onChanged,
        onSubmitted: (_) => onSubmitted?.call(),
        decoration: const InputDecoration(labelText: 'Your name', hintText: 'e.g. Sara'),
      );
}

/// Changes or clears the name the coach uses.
Future<void> showUserNameSheet(BuildContext context, String? current) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
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
    await ref.read(coachSettingsRepositoryProvider).saveUserName(_name.text);
    if (mounted) Navigator.of(context).pop();
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
            // Typing is all this sheet is for, so the keyboard comes with it.
            UserNameField(controller: _name, autofocus: true, onSubmitted: _save),
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
