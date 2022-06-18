import 'package:flutter/material.dart';

Future<void> showMessageDialog({
  required BuildContext context,
  String? title,
  required String text,
}) async {
  return showDialog<void>(
    context: context,
    builder: (_) => MessageDialog(
      title: title,
      text: text,
    ),
  );
}

class MessageDialog extends StatelessWidget {
  const MessageDialog({
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
          onPressed: () => Navigator.pop(context),
          child: const Text("Ok"),
        ),
      ],
    );
  }
}
