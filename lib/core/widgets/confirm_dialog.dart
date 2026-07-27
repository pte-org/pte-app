import 'package:flutter/material.dart';

/// Shared confirm-then-act dialog — every irreversible action (force-submit,
/// logout, discard, etc.) gates behind this instead of each call site
/// building its own `AlertDialog`. Returns `true` only if the user tapped
/// the confirm action; `false` for cancel or dismissal.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  required String cancelLabel,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: Text(cancelLabel)),
        TextButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: Text(confirmLabel)),
      ],
    ),
  );
  return confirmed ?? false;
}
