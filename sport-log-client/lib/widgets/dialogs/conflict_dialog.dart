import 'package:flutter/material.dart';

enum ConflictResolution {
  manual,
  automatic,
}

Future<ConflictResolution> showConflictDialog({
  required BuildContext context,
  String? title,
  required String text,
}) async {
  return (await showDialog<ConflictResolution?>(
    context: context,
    barrierDismissible: false,
    builder: (_) => ConflictDialog(
      title: title,
      text: text,
    ),
  ))!;
}

class ConflictDialog extends StatelessWidget {
  const ConflictDialog({
    required this.title,
    required this.text,
    super.key,
  });

  final String? title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: title == null ? null : Text(title!),
      content: Text(text),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, ConflictResolution.manual),
          child: const Text("Solve manually"),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, ConflictResolution.automatic),
          child: const Text("Delete conflicting local changes"),
        ),
      ],
    );
  }
}
