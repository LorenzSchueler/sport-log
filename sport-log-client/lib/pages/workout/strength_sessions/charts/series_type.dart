import 'package:sport_log/models/movement/movement.dart';
import 'package:sport_log/models/strength/strength_session_stats.dart';
import 'package:sport_log/models/strength/strength_set.dart';

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
  String toDisplayName(MovementDimension dim) {
    switch (this) {
      case SeriesType.maxCount:
        if (dim == MovementDimension.distance) {
          return 'Best Distance';
        }
        break;
      case SeriesType.minCount:
        if (dim == MovementDimension.time) {
          return 'Best Time';
        }
        break;
      case SeriesType.sumCount:
        if (dim == MovementDimension.energy) {
          return 'Total Calories';
        }
        break;
      case SeriesType.avgCount:
        if (dim == MovementDimension.reps) {
          return 'Avg Reps';
        }
        break;
      case SeriesType.maxEorm:
        if (dim == MovementDimension.reps) {
          return 'Best Eorm';
        }
        break;
      case SeriesType.sumVolume:
        if (dim == MovementDimension.reps) {
          return 'Total Volume';
        }
        break;
      case SeriesType.maxWeight:
        if (dim == MovementDimension.reps) {
          return 'Max Weight';
        }
        break;
    }
    throw StateError('${toString()} and ${dim.displayName} doesn\'t work');
  }
}

List<SeriesType> getAvailableSeries(MovementDimension dim) {
  switch (dim) {
    case MovementDimension.reps:
      return [
        SeriesType.maxEorm,
        SeriesType.sumVolume,
        SeriesType.maxWeight,
        SeriesType.avgCount,
      ];
    case MovementDimension.energy:
      return [SeriesType.sumCount];
    case MovementDimension.distance:
      return [SeriesType.maxCount];
    case MovementDimension.time:
      return [SeriesType.minCount];
  }
}

double Function(StrengthSessionStats stats) statsAccessor(SeriesType type) {
  switch (type) {
    case SeriesType.maxCount:
      return (stats) => stats.maxCount.toDouble();
    case SeriesType.minCount:
      return (stats) => stats.minCount.toDouble();
    case SeriesType.sumCount:
      return (stats) => stats.sumCount.toDouble();
    case SeriesType.avgCount:
      return (stats) => stats.sumCount.toDouble() / stats.numSets.toDouble();
    case SeriesType.maxEorm:
      return (stats) => stats.maxEorm ?? 0;
    case SeriesType.sumVolume:
      return (stats) => stats.sumVolume ?? 0;
    case SeriesType.maxWeight:
      return (stats) => stats.maxWeight ?? 0;
  }
}

double Function(StrengthSet set) setAccessor(SeriesType type) {
  switch (type) {
    case SeriesType.maxCount:
    case SeriesType.minCount:
    case SeriesType.sumCount:
    case SeriesType.avgCount:
      return (set) => set.count.toDouble();
    case SeriesType.maxEorm:
      return (set) => set.eorm ?? 0;
    case SeriesType.sumVolume:
      return (set) => set.volume ?? 0;
    case SeriesType.maxWeight:
      return (set) => set.weight ?? 0;
  }
}
