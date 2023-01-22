import 'package:flutter/material.dart' hide Action;
import 'package:sport_log/defaults.dart';
import 'package:sport_log/models/action/action.dart';

Future<Action?> showActionPicker({
  required List<Action> actions,
  required Action? currentAction,
  required BuildContext context,
  bool dismissible = true,
}) async {
  return showDialog<Action>(
    builder: (_) =>
        ActionPickerDialog(actions: actions, currentAction: currentAction),
    barrierDismissible: dismissible,
    context: context,
  );
}

class ActionPickerDialog extends StatelessWidget {
  const ActionPickerDialog({
    required this.actions,
    required this.currentAction,
    super.key,
  });

  final List<Action> actions;
  final Action? currentAction;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: Defaults.edgeInsets.normal,
        child: ListView.separated(
          itemBuilder: (context, index) {
            final action = actions[index];
            return ListTile(
              title: Text(action.name),
              onTap: () => Navigator.pop(context, action),
              selected: action == currentAction,
            );
          },
          itemCount: actions.length,
          separatorBuilder: (context, _) => const Divider(),
          shrinkWrap: true,
        ),
      ),
    );
  }
}
