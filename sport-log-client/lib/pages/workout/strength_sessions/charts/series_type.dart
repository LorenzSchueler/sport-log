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
  String toDisplayName(MovementDimension dim) {
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

double Function(StrengthSessionStats stats) statsAccessor(SeriesType type) {
  switch (type) {
    case SeriesType.maxDistance:
      return (stats) => stats.maxCount.toDouble();
    case SeriesType.minTime:
      return (stats) => stats.minCount.toDouble();
    case SeriesType.sumCalories:
      return (stats) => stats.sumCount.toDouble();
    case SeriesType.maxEorm:
      return (stats) => stats.maxEorm ?? 0;
    case SeriesType.maxWeight:
      return (stats) => stats.maxWeight ?? 0;
    case SeriesType.maxReps:
      return (stats) => stats.maxCount.toDouble();
    case SeriesType.avgReps:
      return (stats) => stats.avgCount;
    case SeriesType.sumVolume:
      return (stats) => stats.sumVolume ?? 0;
  }
}

double Function(StrengthSet set) setAccessor(SeriesType type) {
  switch (type) {
    case SeriesType.maxDistance:
    case SeriesType.minTime:
    case SeriesType.sumCalories:
    case SeriesType.maxEorm:
      return (set) => set.eorm ?? 0;
    case SeriesType.maxWeight:
      return (set) => set.weight ?? 0;
    case SeriesType.maxReps:
      return (set) => set.count.toDouble();
    case SeriesType.avgReps:
      return (set) => set.count.toDouble();
    case SeriesType.sumVolume:
      return (set) => set.volume ?? 0;
  }
}
