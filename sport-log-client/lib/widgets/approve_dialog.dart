import 'package:flutter/material.dart';

Future<bool?> showApproveDialog(
    BuildContext context, String title, String description) {
  return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(description),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel')),
              TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Approve'))
            ],
          ));
}

Future<bool?> showDiscardWarningDialog(BuildContext context) {
  return showApproveDialog(context, 'Discard changes', 'Changes will be lost.');
}
