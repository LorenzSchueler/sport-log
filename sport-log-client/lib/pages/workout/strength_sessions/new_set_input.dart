import 'package:flutter/material.dart';
import 'package:sport_log/models/all.dart';
import 'package:sport_log/pages/workout/strength_sessions/set_inputs/set_duration_input.dart';
import 'package:sport_log/widgets/input_fields/count_weight_input.dart';

class NewSetInput extends StatelessWidget {
  const NewSetInput({
    required this.onNewSet,
    required this.confirmChanges,
    required this.dimension,
    required this.editWeightUnit,
    this.distanceUnit,
    this.editDistanceUnit,
    this.initialCount = 0,
    this.initialWeight,
    this.secondWeight = false,
    this.initialSecondWeight,
    super.key,
  });

  final void Function(
    int count,
    double? weight,
    double? secondWeight,
    DistanceUnit? distanceUnit,
  ) onNewSet;
  final bool confirmChanges;
  final MovementDimension dimension;
  final bool editWeightUnit;
  final DistanceUnit? distanceUnit;
  final bool? editDistanceUnit;
  final int initialCount;
  final double? initialWeight;
  final bool secondWeight;
  final double? initialSecondWeight;

  @override
  Widget build(BuildContext context) {
    return dimension == MovementDimension.time
        ? SetDurationInput(
            onNewSet: (count, weight, secondWeight) =>
                onNewSet(count, weight, secondWeight, null),
            confirmChanges: confirmChanges,
            initialCount: initialCount,
          )
        : CountWeightInput(
            onNewSet: onNewSet,
            confirmChanges: confirmChanges,
            dimension: dimension,
            editWeightUnit: editWeightUnit,
            distanceUnit: distanceUnit,
            editDistanceUnit: editDistanceUnit,
            initialCount: initialCount,
            initialWeight: initialWeight,
            secondWeight: secondWeight,
            initialSecondWeight: initialSecondWeight,
          );
  }
}
