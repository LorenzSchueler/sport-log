import 'package:flutter/material.dart';

Future<bool> showApproveDialog({
  required BuildContext context,
  required String title,
  required String text,
}) async {
  final approved = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(text),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Approve'),
        )
      ],
    ),
  );
  return approved != null && approved;
}

Future<bool> showDiscardWarningDialog(BuildContext context) =>
    showApproveDialog(
      context: context,
      title: 'Discard changes',
      text: 'Changes will be lost.',
    );
