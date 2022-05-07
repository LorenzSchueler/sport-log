import 'package:sport_log/models/movement/movement.dart';
import 'package:sport_log/models/strength/strength_session_stats.dart';
import 'package:sport_log/models/strength/strength_set.dart';

enum SeriesType {
  maxDistance, // m
  minTime, // mSecs
  sumCalories, // cal
  maxEorm, // reps
  maxWeight, // reps
  maxReps, // reps
  avgReps, // reps
  sumVolume, // reps
}

extension DisplayName on SeriesType {
  String toDisplayName() {
    switch (this) {
      case SeriesType.maxDistance:
        return 'Best Distance';
      case SeriesType.minTime:
        return 'Best Time';
      case SeriesType.sumCalories:
        return 'Total Calories';
      case SeriesType.maxEorm:
        return 'Eorm';
      case SeriesType.maxWeight:
        return 'Max Weight';
      case SeriesType.maxReps:
        return 'Max Reps';
      case SeriesType.avgReps:
        return 'Avg Reps';
      case SeriesType.sumVolume:
        return 'Total Volume';
    }
  }
}

List<SeriesType> getAvailableSeries(MovementDimension dim) {
  switch (dim) {
    case MovementDimension.reps:
      return [
        SeriesType.maxEorm,
        SeriesType.maxWeight,
        SeriesType.maxReps,
        SeriesType.avgReps,
        SeriesType.sumVolume,
      ];
    case MovementDimension.energy:
      return [SeriesType.sumCalories];
    case MovementDimension.distance:
      return [SeriesType.maxDistance];
    case MovementDimension.time:
      return [SeriesType.minTime];
  }
}

extension SeriesAccessor on SeriesType {
  double statValue(StrengthSessionStats stats) {
    switch (this) {
      case SeriesType.maxDistance:
        return stats.maxCount.toDouble();
      case SeriesType.minTime:
        return stats.minCount.toDouble();
      case SeriesType.sumCalories:
        return stats.sumCount.toDouble();
      case SeriesType.maxEorm:
        return stats.maxEorm ?? 0;
      case SeriesType.maxWeight:
        return stats.maxWeight ?? 0;
      case SeriesType.maxReps:
        return stats.maxCount.toDouble();
      case SeriesType.avgReps:
        return stats.avgCount;
      case SeriesType.sumVolume:
        return stats.sumVolume ?? 0;
    }
  }

  double setValue(StrengthSet set) {
    switch (this) {
      case SeriesType.maxDistance:
        return set.count.toDouble();
      case SeriesType.minTime:
        return set.count.toDouble();
      case SeriesType.sumCalories:
        return set.count.toDouble();
      case SeriesType.maxEorm:
        return set.eorm ?? 0;
      case SeriesType.maxWeight:
        return set.weight ?? 0;
      case SeriesType.maxReps:
        return set.count.toDouble();
      case SeriesType.avgReps:
        return set.count.toDouble();
      case SeriesType.sumVolume:
        return set.volume ?? 0;
    }
  }
}
