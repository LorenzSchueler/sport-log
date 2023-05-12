import 'package:flutter/material.dart';
import 'package:sport_log/app.dart';

class _DialogOption<T> {
  _DialogOption({required this.name, required this.value});

  final String name;
  final T value;
}

class _Dialog<T> extends StatelessWidget {
  const _Dialog({
    required this.title,
    required this.text,
    required this.options,
    super.key,
  });

  final String? title;
  final String text;
  final List<_DialogOption<T>> options;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: title == null ? null : Text(title!),
      content: SingleChildScrollView(child: Text(text)),
      actions: options
          .map(
            (o) => TextButton(
              onPressed: () => Navigator.pop(context, o.value),
              child: Text(o.name),
            ),
          )
          .toList(),
    );
  }
}

enum ConflictResolution {
  manual,
  automatic;

  bool get isManual => this == ConflictResolution.manual;
  bool get isAutomatic => this == ConflictResolution.automatic;
}

Future<ConflictResolution> showConflictDialog({
  required BuildContext context,
  String? title,
  required String text,
}) async {
  return (await showDialog<ConflictResolution?>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _Dialog(
      title: title,
      text: text,
      options: [
        _DialogOption(name: "Solve manually", value: ConflictResolution.manual),
        _DialogOption(
          name: "Delete conflicting local changes",
          value: ConflictResolution.automatic,
        ),
      ],
    ),
  ))!;
}

enum SystemSettings {
  change,
  ignore;

  bool get isChange => this == SystemSettings.change;
  bool get isIgnore => this == SystemSettings.ignore;
}

Future<SystemSettings> showSystemSettingsDialog({required String text}) async {
  final systemSettings = await showDialog<SystemSettings>(
    context: App.globalContext,
    builder: (context) => _Dialog(
      title: null,
      text: text,
      options: [
        _DialogOption(name: "Change Permissions", value: SystemSettings.change),
        _DialogOption(name: "Ignore", value: SystemSettings.ignore),
      ],
    ),
  );
  return systemSettings ?? SystemSettings.ignore;
}

Future<bool> showApproveDialog({
  required BuildContext context,
  required String title,
  required String text,
}) async {
  final approved = await showDialog<bool>(
    context: context,
    builder: (context) => _Dialog(
      title: title,
      text: text,
      options: [
        _DialogOption(name: "Cancel", value: false),
        _DialogOption(name: "Approve", value: true),
      ],
    ),
  );
  return approved ?? false;
}

Future<bool> showDiscardWarningDialog(BuildContext context) =>
    showApproveDialog(
      context: context,
      title: 'Discard changes',
      text: 'Changes will be lost.',
    );

Future<void> showMessageDialog({
  required BuildContext context,
  String? title,
  required String text,
}) async {
  return showDialog<void>(
    context: context,
    builder: (_) => _Dialog(
      title: title,
      text: text,
      options: [_DialogOption(name: "Ok", value: null)],
    ),
  );
}
