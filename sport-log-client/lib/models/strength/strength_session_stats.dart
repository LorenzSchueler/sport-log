import 'strength_set.dart';
import 'package:sport_log/database/defs.dart';
import 'package:sport_log/database/keys.dart';

class StrengthSessionStats {
  /// list of sets cannot be empty
  factory StrengthSessionStats.fromStrengthSets({
    required List<StrengthSet> sets,
    required DateTime dateTime,
  }) {
    assert(sets.isNotEmpty);
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
    return StrengthSessionStats._(
      dateTime: dateTime,
      numSets: sets.length,
      minCount: minCount!,
      maxCount: maxCount!,
      sumCount: sumCount,
      maxEorm: maxEorm,
      sumVolume: sumVolume,
      maxWeight: maxWeight,
    );
  }

  StrengthSessionStats._({
    required this.dateTime,
    required this.numSets,
    required this.minCount,
    required this.maxCount,
    required this.sumCount,
    required this.maxEorm,
    required this.sumVolume,
    required this.maxWeight,
  });

  DateTime dateTime;
  int numSets;
  int minCount;
  int maxCount;
  int sumCount;
  double? maxEorm;
  double? sumVolume;
  double? maxWeight;

  static const allColumns = [
    Keys.datetime,
    Keys.numSets,
    Keys.minCount,
    Keys.maxCount,
    Keys.sumCount,
    Keys.maxEorm,
    Keys.maxWeight,
    Keys.sumVolume
  ];

  StrengthSessionStats.fromDbRecord(DbRecord r)
      : dateTime = DateTime.parse(r[Keys.datetime]! as String),
        numSets = r[Keys.numSets]! as int,
        minCount = r[Keys.minCount]! as int,
        maxCount = r[Keys.maxCount]! as int,
        sumCount = r[Keys.sumCount]! as int,
        maxEorm = r[Keys.maxEorm] as double?,
        maxWeight = r[Keys.maxWeight] as double?,
        sumVolume = r[Keys.sumVolume] as double?;

  // this is only for debugging/pretty-printing
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      Keys.datetime: dateTime,
      Keys.numSets: numSets,
      Keys.minCount: minCount,
      Keys.maxCount: maxCount,
      Keys.sumCount: sumCount,
      Keys.maxEorm: maxEorm,
      Keys.maxWeight: maxWeight,
      Keys.sumVolume: sumVolume,
    };
  }
}
