import 'package:flutter/material.dart';
import 'package:sport_log/app.dart';

Future<bool> showSystemSettingsDialog({required String text}) async {
  final ignore = await showDialog<bool>(
    context: App.globalContext,
    builder: (context) => SystemSettingsDialog(text: text),
  );
  return ignore == null || ignore;
}

class SystemSettingsDialog extends StatelessWidget {
  const SystemSettingsDialog({required this.text, Key? key}) : super(key: key);

  final String text;

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
