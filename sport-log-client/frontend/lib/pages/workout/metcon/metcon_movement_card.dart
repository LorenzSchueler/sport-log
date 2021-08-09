
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sport_log/models/metcon/ui_metcon.dart';
import 'package:sport_log/models/movement/movement.dart';
import 'package:sport_log/repositories/movement_repository.dart';
import 'package:sport_log/widgets/int_picker.dart';

import 'movement_picker_dialog.dart';

class MetconMovementCard extends StatelessWidget {
  const MetconMovementCard({
    required this.deleteMetconMovement,
    required this.editMetconMovement,
    required this.move,
    required this.index,
    Key? key,
  }) : super(key: key);

  final UiMetconMovement move;
  final int index;
  final Function(UiMetconMovement) editMetconMovement;
  final Function() deleteMetconMovement;

  static const _weightDefaultValue = 10.0;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 0),
      child: Column(
        children: [
          ListTile(
            title: Text(
                context.read<MovementRepository>()
                    .getMovement(move.movementId)!.name
            ),
            onTap: () => showMovementPickerDialog(context, (id) {
              move.movementId = id;
              editMetconMovement(move);
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
                  index: index
                ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IntPicker(initialValue: move.count, setValue: (count) {
                move.count = count;
                editMetconMovement(move);
              }),
              const Padding(padding: EdgeInsets.all(8)),
              DropdownButton(
                value: move.unit,
                onChanged: (MovementUnit? u) {
                  if (u != null) {
                    move.unit = u;
                    editMetconMovement(move);
                  }
                },
                items: MovementUnit.values.map((u) =>
                    DropdownMenuItem(
                      child: Text(u.toDisplayName()),
                      key: ValueKey(u.toString()),
                      value: u,
                    )
                ).toList(),
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
                    move.weight = _weightDefaultValue;
                    editMetconMovement(move);
                  },
                  icon: const Icon(Icons.add),
                  label: const Text("Add weight..."),
                ),
              if (move.weight != null)
                const Text("Float picker to come"),
            ],
          ),
        ],
      ),
    );
  }

  static void showMovementPickerDialog(
      BuildContext context,
      Function(Int64) onPicked
  ) {
    showDialog(
      context: context,
      builder: (_) => const MovementPickerDialog(),
    ).then((movementId) {
      if (movementId is Int64) {
        onPicked(movementId);
      }
    });
  }

}