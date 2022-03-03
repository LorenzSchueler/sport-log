import 'package:flutter/material.dart';

Future<bool?> showApproveDialog(
  BuildContext context,
  String title,
  String description,
) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(description),
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
}

Future<bool?> showDiscardWarningDialog(BuildContext context) {
  return showApproveDialog(context, 'Discard changes', 'Changes will be lost.');
}

Future<void> showWarning(
  BuildContext context,
  String title,
  String description,
) {
  return showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(description),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Ok'),
        ),
      ],
    ),
  );
}
