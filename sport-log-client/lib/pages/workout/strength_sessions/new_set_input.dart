import 'package:flutter/material.dart';
import 'package:sport_log/models/all.dart';
import 'package:sport_log/pages/workout/strength_sessions/set_inputs/set_duration_input.dart';
import 'package:sport_log/widgets/form_widgets/count_weight_picker.dart';

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
        return CountWeightPicker(countLabel: "Reps", setValue: onNewSet);
      case MovementDimension.time:
        return SetDurationInput(onNewSet: onNewSet);
      case MovementDimension.distance:
        return CountWeightPicker(
          countLabel: "Distance",
          countUnit: "m",
          setValue: onNewSet,
        );
      case MovementDimension.energy:
        return CountWeightPicker(
          countLabel: "Energy",
          countUnit: "cal",
          setValue: onNewSet,
        );
    }
  }
}
