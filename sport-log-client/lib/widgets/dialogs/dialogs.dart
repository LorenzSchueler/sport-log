import 'package:flutter/material.dart';
import 'package:sport_log/app.dart';

class _DialogOption<T> {
  _DialogOption({required this.name, required this.value, this.color});

  final String name;
  final T value;
  final Color? color;
}

class _Dialog<T> extends StatelessWidget {
  const _Dialog({
    required this.title,
    required this.text,
    required this.options,
    super.key,
  });

  final String title;
  final String text;
  final List<_DialogOption<T>> options;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(child: Text(text)),
      actions: options
          .map(
            (o) => TextButton(
              onPressed: () => Navigator.pop(context, o.value),
              child: Text(
                o.name,
                style: TextStyle(color: o.color),
              ),
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
  required String title,
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

enum PermissionSettings {
  change,
  ignore;

  bool get isChange => this == PermissionSettings.change;
  bool get isIgnore => this == PermissionSettings.ignore;
}

Future<PermissionSettings> showPermissionRequiredDialog({
  required String text,
}) async {
  final systemSettings = await showDialog<PermissionSettings>(
    context: App.globalContext,
    builder: (_) => _Dialog(
      title: "Permission Required",
      text: text,
      options: [
        _DialogOption(
          name: "Change Permissions",
          value: PermissionSettings.change,
        ),
        _DialogOption(name: "Ignore", value: PermissionSettings.ignore),
      ],
    ),
  );
  return systemSettings ?? PermissionSettings.ignore;
}

enum ServiceSettings {
  change,
  ignore;

  bool get isChange => this == ServiceSettings.change;
  bool get isIgnore => this == ServiceSettings.ignore;
}

Future<ServiceSettings> showServiceRequiredDialog({
  required String title,
  required String text,
}) async {
  final systemSettings = await showDialog<ServiceSettings>(
    context: App.globalContext,
    builder: (_) => _Dialog(
      title: title,
      text: text,
      options: [
        _DialogOption(name: "Enable", value: ServiceSettings.change),
        _DialogOption(name: "Ignore", value: ServiceSettings.ignore),
      ],
    ),
  );
  return systemSettings ?? ServiceSettings.ignore;
}

Future<bool> showApproveDialog({
  required BuildContext context,
  required String title,
  required String text,
}) async {
  final approved = await showDialog<bool>(
    context: context,
    builder: (_) => _Dialog(
      title: title,
      text: text,
      options: [
        _DialogOption(
          name: "Cancel",
          value: false,
          color: Theme.of(context).colorScheme.errorContainer,
        ),
        _DialogOption(
          name: "Approve",
          value: true,
          color: Theme.of(context).colorScheme.error,
        ),
      ],
    ),
  );
  return approved ?? false;
}

Future<bool> showDiscardWarningDialog(BuildContext context) async {
  final discard = await showDialog<bool>(
    context: context,
    builder: (_) => _Dialog(
      title: 'Discard Changes',
      text: 'Changes will be lost.',
      options: [
        _DialogOption(
          name: "Cancel",
          value: false,
          color: Theme.of(context).colorScheme.errorContainer,
        ),
        _DialogOption(
          name: "Discard Changes",
          value: true,
          color: Theme.of(context).colorScheme.error,
        ),
      ],
    ),
  );
  return discard ?? false;
}

Future<bool> showDeleteWarningDialog(
  BuildContext context,
  String entityName,
) async {
  final delete = await showDialog<bool>(
    context: context,
    builder: (_) => _Dialog(
      title: 'Delete $entityName?',
      text: 'This $entityName will be permanently deleted.',
      options: [
        _DialogOption(
          name: "Cancel",
          value: false,
          color: Theme.of(context).colorScheme.errorContainer,
        ),
        _DialogOption(
          name: "Delete",
          value: true,
          color: Theme.of(context).colorScheme.error,
        ),
      ],
    ),
  );
  return delete ?? false;
}

Future<bool> showUpdateDialog(BuildContext context) async {
  final update = await showDialog<bool>(
    context: context,
    builder: (_) => _Dialog(
      title: 'Install Update?',
      text:
          'An update for Sport-Log is available. Do you want to download and install it now?',
      options: [
        _DialogOption(name: "No", value: false),
        _DialogOption(name: "Yes", value: true),
      ],
    ),
  );
  return update ?? false;
}

Future<void> showMessageDialog({
  required BuildContext context,
  required String title,
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
