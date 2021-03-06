import 'package:flutter/material.dart' hide Action;
import 'package:sport_log/defaults.dart';
import 'package:sport_log/models/action/action.dart';

Future<Action?> showActionPicker({
  required List<Action> actions,
  required BuildContext context,
  bool dismissable = true,
}) async {
  return showDialog<Action>(
    builder: (_) => ActionPickerDialog(actions: actions),
    barrierDismissible: dismissable,
    context: context,
  );
}

class ActionPickerDialog extends StatelessWidget {
  const ActionPickerDialog({required this.actions, super.key});

  final List<Action> actions;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: Defaults.edgeInsets.normal,
        child: ListView.separated(
          itemBuilder: (context, index) => ListTile(
            title: Text(actions[index].name),
            onTap: () {
              Navigator.pop(context, actions[index]);
            },
          ),
          itemCount: actions.length,
          separatorBuilder: (context, _) => const Divider(),
          shrinkWrap: true,
        ),
      ),
    );
  }
}
