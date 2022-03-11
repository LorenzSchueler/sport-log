import 'package:flutter/material.dart';
import 'package:sport_log/models/all.dart';
import 'package:sport_log/pages/workout/strength_sessions/set_inputs/set_duration_input.dart';
import 'package:sport_log/widgets/input_fields/count_weight_input.dart';

class NewSetInput extends StatelessWidget {
  const NewSetInput({
    Key? key,
    required this.onNewSet,
    required this.confirmChanges,
    required this.dimension,
    this.distanceUnit,
    this.initialCount = 0,
    this.initialWeight,
    this.secondWeight = false,
    this.initialSecondWeight,
  }) : super(key: key);

  final void Function(int count, double? weight, double? secondWeight) onNewSet;
  final bool confirmChanges;
  final MovementDimension dimension;
  final DistanceUnit? distanceUnit;
  final int initialCount;
  final double? initialWeight;
  final bool secondWeight;
  final double? initialSecondWeight;

  @override
  Widget build(BuildContext context) {
    switch (dimension) {
      case MovementDimension.reps:
        return CountWeightInput(
          setValue: onNewSet,
          confirmChanges: confirmChanges,
          countLabel: dimension.displayName,
          initialCount: initialCount,
          initialWeight: initialWeight,
          secondWeight: secondWeight,
          initialSecondWeight: initialSecondWeight,
        );
      case MovementDimension.time:
        return SetDurationInput(
          onNewSet: onNewSet,
          confirmChanges: confirmChanges,
        );
      case MovementDimension.distance:
        return CountWeightInput(
          setValue: onNewSet,
          confirmChanges: confirmChanges,
          countLabel: dimension.displayName,
          countUnit: (distanceUnit ?? DistanceUnit.m).displayName,
          initialCount: initialCount,
          initialWeight: initialWeight,
          secondWeight: secondWeight,
          initialSecondWeight: initialSecondWeight,
        );
      case MovementDimension.energy:
        return CountWeightInput(
          setValue: onNewSet,
          confirmChanges: confirmChanges,
          countLabel: dimension.displayName,
          initialCount: initialCount,
          initialWeight: initialWeight,
          secondWeight: secondWeight,
          initialSecondWeight: initialSecondWeight,
        );
    }
  }
}
