import 'package:flutter/material.dart';
import 'package:sport_log/models/all.dart';
import 'package:sport_log/pages/workout/strength_sessions/set_inputs/set_duration_input.dart';
import 'package:sport_log/widgets/form_widgets/count_weight_picker.dart';

class NewSetInput extends StatelessWidget {
  const NewSetInput({
    Key? key,
    required this.onNewSet,
    required this.confirmChanges,
    required this.dimension,
    this.distanceUnit,
    this.initialCount = 0,
    this.initialWeight,
  }) : super(key: key);

  final void Function(int count, double? weight) onNewSet;
  final bool confirmChanges;
  final MovementDimension dimension;
  final DistanceUnit? distanceUnit;
  final int initialCount;
  final double? initialWeight;

  @override
  Widget build(BuildContext context) {
    switch (dimension) {
      case MovementDimension.reps:
        return CountWeightPicker(
          setValue: onNewSet,
          confirmChanges: confirmChanges,
          countLabel: dimension.displayName,
          initialCount: initialCount,
          initialWeight: initialWeight,
        );
      case MovementDimension.time:
        return SetDurationInput(
          onNewSet: onNewSet,
          confirmChanges: confirmChanges,
        );
      case MovementDimension.distance:
        return CountWeightPicker(
          setValue: onNewSet,
          confirmChanges: confirmChanges,
          countLabel: dimension.displayName,
          countUnit: (distanceUnit ?? DistanceUnit.m).displayName,
          initialCount: initialCount,
          initialWeight: initialWeight,
        );
      case MovementDimension.energy:
        return CountWeightPicker(
          setValue: onNewSet,
          confirmChanges: confirmChanges,
          countLabel: dimension.displayName,
          initialCount: initialCount,
          initialWeight: initialWeight,
        );
    }
  }
}
