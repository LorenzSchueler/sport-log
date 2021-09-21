import 'strength_set.dart';
import 'package:sport_log/database/defs.dart';
import 'package:sport_log/database/keys.dart';

class StrengthSessionStats {
  StrengthSessionStats({
    required this.numSets,
    required this.minCount,
    required this.maxCount,
    required this.sumCount,
    required this.maxEorm,
    required this.sumVolume,
    required this.maxWeight,
  });

  StrengthSessionStats.unsafeDefault()
      : numSets = 0,
        minCount = -1,
        maxCount = -1,
        sumCount = 0,
        maxEorm = null,
        sumVolume = null,
        maxWeight = null;

  int numSets;
  int minCount;
  int maxCount;
  int sumCount;
  double? maxEorm;
  double? sumVolume;
  double? maxWeight;

  void updateWithStrengthSet(StrengthSet set) {
    numSets += 1;
    if (minCount < 0 || set.count < minCount) {
      minCount = set.count;
    }
    if (maxCount < 0 || set.count > maxCount) {
      maxCount = set.count;
    }
    sumCount += set.count;
    final eorm = set.eorm;
    if (eorm != null) {
      if (maxEorm == null || eorm > maxEorm!) {
        maxEorm = eorm;
      }
    }
    final volume = set.volume;
    if (volume != null) {
      if (sumVolume == null) {
        sumVolume = volume;
      } else {
        sumVolume = sumVolume! + volume;
      }
    }
    final weight = set.weight;
    if (weight != null) {
      if (maxWeight == null) {
        maxWeight = weight;
      } else {
        maxWeight = maxWeight! + weight;
      }
    }
  }

  static const allColumns = [
    Keys.numSets,
    Keys.minCount,
    Keys.maxCount,
    Keys.sumCount,
    Keys.maxEorm,
    Keys.maxWeight,
    Keys.sumVolume
  ];

  StrengthSessionStats.fromDbRecord(DbRecord r)
      : numSets = r[Keys.numSets]! as int,
        minCount = r[Keys.minCount]! as int,
        maxCount = r[Keys.maxCount]! as int,
        sumCount = r[Keys.sumCount]! as int,
        maxEorm = r[Keys.maxEorm] as double?,
        maxWeight = r[Keys.maxWeight] as double?,
        sumVolume = r[Keys.sumVolume] as double?;
}
