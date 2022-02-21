import 'package:sport_log/database/table.dart';
import 'package:sport_log/database/table_accessor.dart';
import 'package:sport_log/helpers/formatting.dart';
import 'package:sport_log/models/movement/movement.dart';
import 'package:sport_log/models/strength/all.dart';

class StrengthSessionStats {
  DateTime datetime;
  int numSets;
  int minCount;
  int maxCount;
  int sumCount;
  double avgCount;
  double? maxEorm;
  double? sumVolume;
  double? maxWeight;

  StrengthSessionStats._({
    required this.datetime,
    required this.numSets,
    required this.minCount,
    required this.maxCount,
    required this.sumCount,
    required this.avgCount,
    required this.maxEorm,
    required this.sumVolume,
    required this.maxWeight,
  });

  factory StrengthSessionStats.fromStrengthSets(
      DateTime datetime, List<StrengthSet> sets) {
    int? minCount;
    int? maxCount;
    int sumCount = 0;
    double? maxEorm;
    double? maxWeight;
    double? sumVolume;

    for (final set in sets) {
      if (minCount == null || set.count < minCount) {
        minCount = set.count;
      }
      if (maxCount == null || set.count > maxCount) {
        maxCount = set.count;
      }
      sumCount += set.count;
      final eorm = set.eorm;
      if (eorm != null) {
        if (maxEorm == null || eorm > maxEorm) {
          maxEorm = eorm;
        }
      }
      final volume = set.volume;
      if (volume != null) {
        if (sumVolume == null) {
          sumVolume = volume;
        } else {
          sumVolume += volume;
        }
      }
      final weight = set.weight;
      if (weight != null) {
        if (maxWeight == null) {
          maxWeight = weight;
        } else {
          maxWeight += weight;
        }
      }
    }
    double avgCount = sumCount / sets.length;

    return StrengthSessionStats._(
      datetime: datetime,
      numSets: sets.length,
      minCount: minCount!,
      maxCount: maxCount!,
      sumCount: sumCount,
      avgCount: avgCount,
      maxEorm: maxEorm,
      sumVolume: sumVolume,
      maxWeight: maxWeight,
    );
  }

  StrengthSessionStats.fromDbRecord(DbRecord r)
      : datetime = DateTime.parse(r[Columns.datetime]! as String),
        numSets = r[Columns.numSets]! as int,
        minCount = r[Columns.minCount]! as int,
        maxCount = r[Columns.maxCount]! as int,
        sumCount = r[Columns.sumCount]! as int,
        avgCount = (r[Columns.sumCount]! as int).toDouble() /
            (r[Columns.numSets]! as int).toDouble(),
        maxEorm = r[Columns.maxEorm] as double?,
        maxWeight = r[Columns.maxWeight] as double?,
        sumVolume = r[Columns.sumVolume] as double?;

  // this is only for debugging/pretty-printing
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      Columns.numSets: numSets,
      Columns.minCount: minCount,
      Columns.maxCount: maxCount,
      Columns.sumCount: sumCount,
      Columns.maxEorm: maxEorm,
      Columns.maxWeight: maxWeight,
      Columns.sumVolume: sumVolume,
    };
  }

  String toDisplayName(MovementDimension dimension) {
    switch (dimension) {
      case MovementDimension.reps:
        return [
          if (maxEorm != null) '1RM: ${roundedWeight(maxEorm!)}',
          if (sumVolume != null) 'Vol: ${roundedWeight(sumVolume!)}',
          if (maxWeight != null) 'Max Weight: ${roundedWeight(maxWeight!)}',
          'Avg Reps: ${roundedValue(avgCount)}',
        ].join(' • ');
      case MovementDimension.time:
        return 'Best time: ${formatDuration(Duration(milliseconds: minCount))}';
      case MovementDimension.distance:
        return 'Best distance: ${formatDistance(maxCount)}';
      case MovementDimension.energy:
        return 'Total energy: ${sumCount}cals';
    }
  }
}
