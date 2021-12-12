import 'package:flutter/material.dart';
import 'package:sport_log/models/all.dart';
import 'package:sport_log/pages/workout/strength_sessions/set_inputs/set_duration_input.dart';
import 'package:sport_log/pages/workout/strength_sessions/set_inputs/set_reps_input.dart';

class NewSetInput extends StatelessWidget {
  const NewSetInput({
    Key? key,
    required this.dimension,
    required this.onNewSet,
  }) : super(key: key);

  final MovementDimension dimension;
  final void Function(int count, [double? weight]) onNewSet;

  @override
  Widget build(BuildContext context) {
    switch (dimension) {
      case MovementDimension.reps:
        return BottomAppBar(child: SetRepsInput(onNewSet: onNewSet));
      case MovementDimension.time:
        return BottomAppBar(child: SetDurationInput(onNewSet: onNewSet));
      case MovementDimension.distance:
        // TODO: Handle this case.
        break;
      case MovementDimension.energy:
        // TODO: Handle this case.
        break;
    }
    return Container(
      color: Colors.red,
      width: double.infinity,
      height: 70,
    );
  }
}