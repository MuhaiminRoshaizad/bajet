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
