import 'package:flutter/material.dart';
import 'package:sport_log/app.dart';

Future<bool?> showSystemSettingsDialog({required String text}) {
  return showDialog<bool>(
    context: App.globalContext,
    builder: (context) => SystemSettingsDialog(text: text),
  );
}

class SystemSettingsDialog extends StatelessWidget {
  final String text;

  const SystemSettingsDialog({required this.text, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Text(text),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Ignore'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Change Permission'),
        )
      ],
    );
  }
}
