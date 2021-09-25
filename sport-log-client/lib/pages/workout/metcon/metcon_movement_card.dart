import 'package:flutter/material.dart';
import 'package:sport_log/models/metcon/all.dart';
import 'package:sport_log/models/movement/movement.dart';
import 'package:sport_log/widgets/form_widgets/int_picker.dart';
import 'package:sport_log/widgets/movement_picker.dart';

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
            onTap: () async {
              final movement = await showMovementPickerDialog(context);
              if (movement != null) {
                mmd.movement = movement;
                mmd.metconMovement.movementId = movement.id;
                editMetconMovementDescription(mmd);
              }
            },
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
              Text(mmd.movement.unit.toDisplayName()),
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
}
