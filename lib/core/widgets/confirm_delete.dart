import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Asks before something is removed. Keep is the safe default; the
/// destructive choice is filled in the warning colour so it never reads as
/// the ordinary way on. Returns true only when the owner chose [action].
Future<bool> confirmDelete(BuildContext context, {required String title, required String message, String action = 'Delete'}) async {
  final c = context.colors;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Keep')),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(backgroundColor: c.bad, foregroundColor: c.onBad),
          child: Text(action),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

/// The Delete at the foot of an edit sheet: outlined in the warning colour,
/// below Save, so it is never mistaken for the way to finish. Without
/// [onPressed] it is shown disabled, for something that cannot go yet.
class DeleteButton extends StatelessWidget {
  const DeleteButton({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.delete_outline_rounded),
      label: Text(label),
      style: OutlinedButton.styleFrom(foregroundColor: c.bad, side: BorderSide(color: c.bad.withValues(alpha: 0.5)), minimumSize: const Size.fromHeight(52)),
    );
  }
}
