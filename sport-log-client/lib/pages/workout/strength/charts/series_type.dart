import 'package:sport_log/models/movement/movement.dart';

enum SeriesType {
  maxCount, // m
  minCount, // mSecs
  sumCount, // cal
  avgCount, // reps (maybe even with maxWeight)
  maxEorm, // reps
  sumVolume, // reps
  maxWeight, // reps
}

extension DisplayName on SeriesType {
  String toDisplayName(MovementUnit unit) {
    switch (this) {
      case SeriesType.maxCount:
        if (unit == MovementUnit.m) {
          return 'Best Distance';
        }
        break;
      case SeriesType.minCount:
        if (unit == MovementUnit.msecs) {
          return 'Best Time';
        }
        break;
      case SeriesType.sumCount:
        if (unit == MovementUnit.cals) {
          return 'Total Calories';
        }
        break;
      case SeriesType.avgCount:
        if (unit == MovementUnit.reps) {
          return 'Avg Reps';
        }
        break;
      case SeriesType.maxEorm:
        if (unit == MovementUnit.reps) {
          return 'Best Eorm';
        }
        break;
      case SeriesType.sumVolume:
        if (unit == MovementUnit.reps) {
          return 'Total Volume';
        }
        break;
      case SeriesType.maxWeight:
        if (unit == MovementUnit.reps) {
          return 'Max Weight';
        }
        break;
    }
    throw StateError('${toString()} and ${unit.toDisplayName()} doesn\'t work');
  }
}

List<SeriesType> getAvailableSeries(MovementUnit unit) {
    switch (unit) {
      case MovementUnit.reps:
        return [
          SeriesType.maxEorm,
          SeriesType.sumVolume,
          SeriesType.maxWeight,
          SeriesType.avgCount,
        ];
      case MovementUnit.cals:
        return [SeriesType.sumCount];
      case MovementUnit.m:
        return [SeriesType.maxCount];
      case MovementUnit.msecs:
        return [SeriesType.minCount];
      case MovementUnit.km:
        throw StateError('MovementUnit.km cannot be in a strength session.');
      case MovementUnit.yards:
        throw StateError('MovementUnit.yard cannot be in a strength session.');
      case MovementUnit.feet:
        throw StateError('MovementUnit.foot cannot be in a strength session.');
      case MovementUnit.miles:
        throw StateError('MovementUnit.foot cannot be in a strength session.');
    }
}
