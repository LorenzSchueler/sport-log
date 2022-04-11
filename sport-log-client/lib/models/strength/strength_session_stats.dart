import 'package:json_annotation/json_annotation.dart';
import 'package:sport_log/database/table.dart';
import 'package:sport_log/database/table_accessor.dart';
import 'package:sport_log/helpers/extensions/date_time_extension.dart';
import 'package:sport_log/helpers/extensions/iterable_extension.dart';
import 'package:sport_log/helpers/extensions/formatting.dart';
import 'package:sport_log/models/movement/movement.dart';
import 'package:sport_log/models/strength/all.dart';

part 'strength_session_stats.g.dart';

@JsonSerializable()
class StrengthSessionStats extends JsonSerializable {
  DateTime datetime;
  int numSets;
  int minCount;
  int maxCount;
  int sumCount;
  double avgCount;
  double? maxEorm;
  double? sumVolume;
  double? maxWeight;

  StrengthSessionStats({
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
    DateTime datetime,
    List<StrengthSet> sets,
  ) {
    int minCount = sets.map((s) => s.count).min;
    int maxCount = sets.map((s) => s.count).max;
    int sumCount = sets.map((s) => s.count).sum;
    double? maxWeight = sets.map((s) => s.weight).max;
    double? maxEorm = sets.map((s) => s.eorm).max;
    double? sumVolume = sets.map((s) => s.volume).sum;
    double avgCount = sets.isEmpty ? 0 : sumCount / sets.length;

    return StrengthSessionStats(
      datetime: datetime,
      numSets: sets.length,
      minCount: minCount,
      maxCount: maxCount,
      sumCount: sumCount,
      avgCount: avgCount,
      maxEorm: maxEorm,
      sumVolume: sumVolume,
      maxWeight: maxWeight,
    );
  }

  factory StrengthSessionStats.fromDbRecord(DbRecord r, {String prefix = ''}) {
    final numSets = r[prefix + Columns.numSets]! as int;
    final sumCount = r[prefix + Columns.sumCount]! as int;
    double avgCount = numSets == 0 ? 0 : sumCount / numSets;
    return StrengthSessionStats(
      datetime: DateTime.parse(r[prefix + Columns.datetime]! as String),
      numSets: numSets,
      minCount: r[prefix + Columns.minCount]! as int,
      maxCount: r[prefix + Columns.maxCount]! as int,
      sumCount: sumCount,
      avgCount: avgCount,
      maxEorm: r[prefix + Columns.maxEorm] as double?,
      maxWeight: r[prefix + Columns.maxWeight] as double?,
      sumVolume: r[prefix + Columns.sumVolume] as double?,
    );
  }

  factory StrengthSessionStats.fromJson(Map<String, dynamic> json) =>
      _$StrengthSessionStatsFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$StrengthSessionStatsToJson(this);

  String toDisplayName(MovementDimension dimension) {
    switch (dimension) {
      case MovementDimension.reps:
        return [
          if (maxEorm != null) '1RM: ${roundedWeight(maxEorm!)}',
          if (sumVolume != null) 'Vol: ${roundedWeight(sumVolume!)}',
          if (maxWeight != null) 'Max Weight: ${roundedWeight(maxWeight!)}',
          'Avg Reps: ${avgCount.toStringAsFixed(1)}',
        ].join(' • ');
      case MovementDimension.time:
        return 'Best time: ${Duration(milliseconds: minCount).formatTimeWithMillis}';
      case MovementDimension.distance:
        return 'Best distance: ${formatDistance(maxCount)}';
      case MovementDimension.energy:
        return 'Total energy: ${sumCount}cals';
    }
  }
}
