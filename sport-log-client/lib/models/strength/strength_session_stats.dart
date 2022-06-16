import 'package:collection/collection.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:sport_log/database/table.dart';
import 'package:sport_log/database/table_accessor.dart';
import 'package:sport_log/helpers/extensions/date_time_extension.dart';
import 'package:sport_log/helpers/extensions/formatting.dart';
import 'package:sport_log/helpers/extensions/iterable_extension.dart';
import 'package:sport_log/models/movement/movement.dart';
import 'package:sport_log/models/strength/all.dart';

part 'strength_session_stats.g.dart';

@JsonSerializable()
class StrengthSessionStats extends JsonSerializable {
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
    MovementDimension movementDimension,
    List<StrengthSet> sets,
  ) {
    int minCount = sets.map((s) => s.count).minOrNull ?? 0;
    int maxCount = sets.map((s) => s.count).maxOrNull ?? 0;
    int sumCount = sets.map((s) => s.count).sum;
    double? maxWeight = sets.map((s) => s.weight).filterNotNull().maxOrNull;
    double? maxEorm =
        sets.map((s) => s.eorm(movementDimension)).filterNotNull().maxOrNull;
    double? sumVolume = sets.map((s) => s.volume).filterNotNull().sum;
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

  DateTime datetime;
  int numSets;
  int minCount;
  int maxCount;
  int sumCount;
  double avgCount;
  double? maxEorm;
  double? sumVolume;
  double? maxWeight;

  @override
  Map<String, dynamic> toJson() => _$StrengthSessionStatsToJson(this);

  String toDisplayName(MovementDimension dimension) {
    switch (dimension) {
      case MovementDimension.reps:
        return [
          if (maxEorm != null) '1RM: ${formatWeight(maxEorm!)}',
          if (sumVolume != null) 'Vol: ${formatWeight(sumVolume!)}',
          if (maxWeight != null) 'Max Weight: ${formatWeight(maxWeight!)}',
          'Avg Reps: ${avgCount.toStringAsFixed(1)}',
        ].join(' • ');
      case MovementDimension.time:
        return 'Best time: ${Duration(milliseconds: minCount).formatMsMill}';
      case MovementDimension.distance:
        return 'Best distance: $maxCount m';
      case MovementDimension.energy:
        return 'Total energy: $sumCount cal';
    }
  }
}
