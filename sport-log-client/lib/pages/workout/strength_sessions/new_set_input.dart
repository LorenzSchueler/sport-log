import 'package:flutter/material.dart';
import 'package:sport_log/models/all.dart';
import 'package:sport_log/pages/workout/strength_sessions/set_inputs/set_duration_input.dart';
import 'package:sport_log/widgets/form_widgets/count_weight_picker.dart';

class NewSetInput extends StatelessWidget {
  const NewSetInput({
    Key? key,
    required this.onNewSet,
    required this.dimension,
    this.distanceUnit,
    this.initialCount = 0,
    this.initialWeight,
  }) : super(key: key);

  final int initialCount;
  final double? initialWeight;
  final MovementDimension dimension;
  final DistanceUnit? distanceUnit;
  final void Function(int count, double? weight) onNewSet;

  @override
  Widget build(BuildContext context) {
    switch (dimension) {
      case MovementDimension.reps:
        return CountWeightPicker(
          countLabel: dimension.displayName,
          setValue: onNewSet,
          initialCount: initialCount,
          initialWeight: initialWeight,
        );
      case MovementDimension.time:
        return SetDurationInput(onNewSet: onNewSet);
      case MovementDimension.distance:
        return CountWeightPicker(
          countLabel: dimension.displayName,
          countUnit: (distanceUnit ?? DistanceUnit.m).displayName,
          setValue: onNewSet,
          initialCount: initialCount,
          initialWeight: initialWeight,
        );
      case MovementDimension.energy:
        return CountWeightPicker(
          countLabel: dimension.displayName,
          setValue: onNewSet,
          initialCount: initialCount,
          initialWeight: initialWeight,
        );
    }
  }
}
