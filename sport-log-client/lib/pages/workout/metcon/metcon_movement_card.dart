import 'package:flutter/material.dart';
import 'package:sport_log/models/metcon/all.dart';
import 'package:sport_log/models/movement/movement.dart';
import 'package:sport_log/widgets/int_picker.dart';

import 'movement_picker_dialog.dart';

class MetconMovementCard extends StatelessWidget {
  const MetconMovementCard({
    required this.deleteMetconMovement,
    required this.editMetconMovementDescription,
    required this.mmd,
    Key? key,
  }) : super(key: key);

  final MetconMovementDescription mmd;
  final Function(MetconMovementDescription) editMetconMovementDescription;
  final Function() deleteMetconMovement;

  static const _weightDefaultValue = 10.0;

  @override
  Widget build(BuildContext context) {
    final move = mmd.metconMovement;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 0),
      child: Column(
        children: [
          ListTile(
            title: Text(mmd.movement.name),
            onTap: () => showMovementPickerDialog(context, (mm) {
              mmd.movement = mm;
              mmd.metconMovement.movementId = mm.id;
              editMetconMovementDescription(mmd);
            }),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    deleteMetconMovement();
                  },
                ),
                ReorderableDragStartListener(
                    child: const Icon(Icons.drag_handle),
                    index: move.movementNumber),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IntPicker(
                  initialValue: move.count,
                  setValue: (count) {
                    mmd.metconMovement.count = count;
                    editMetconMovementDescription(mmd);
                  }),
              const Padding(padding: EdgeInsets.all(8)),
              DropdownButton(
                value: move.movementUnit,
                onChanged: (MovementUnit? u) {
                  if (u != null) {
                    mmd.metconMovement.movementUnit = u;
                    editMetconMovementDescription(mmd);
                  }
                },
                items: MovementUnit.values
                    .map((u) => DropdownMenuItem(
                          child: Text(u.toDisplayName()),
                          key: ValueKey(u.toString()),
                          value: u,
                        ))
                    .toList(),
              ),
              const Padding(padding: EdgeInsets.all(8)),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (move.weight == null)
                OutlinedButton.icon(
                  onPressed: () {
                    mmd.metconMovement.weight = _weightDefaultValue;
                    editMetconMovementDescription(mmd);
                  },
                  icon: const Icon(Icons.add),
                  label: const Text("Add weight..."),
                ),
              if (move.weight != null) const Text("Float picker to come"),
            ],
          ),
        ],
      ),
    );
  }

  static void showMovementPickerDialog(
      BuildContext context, Function(Movement) onPicked) {
    showDialog<Movement>(
      context: context,
      builder: (_) => const MovementPickerDialog(),
    ).then((movement) {
      if (movement is Movement) {
        onPicked(movement);
      }
    });
  }
}
