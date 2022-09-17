import 'package:collection/collection.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:sport_log/helpers/extensions/date_time_extension.dart';
import 'package:sport_log/helpers/extensions/formatting.dart';
import 'package:sport_log/models/movement/movement.dart';
import 'package:sport_log/models/strength/all.dart';

part 'strength_session_stats.g.dart';

@JsonSerializable()
class StrengthSessionStats extends JsonSerializable {
  StrengthSessionStats({
    required this.datetime,
    required this.numSets,
    required this.maxWeight,
    required this.avgWeight,
    required this.minCount,
    required this.maxCount,
    required this.sumCount,
    required this.avgCount,
    required this.maxEorm,
    required this.sumVolume,
  });

  factory StrengthSessionStats.fromStrengthSets(
    DateTime datetime,
    MovementDimension movementDimension,
    List<StrengthSet> sets,
  ) {
    int numSets = sets.length;
    double? maxWeight = sets.map((s) => s.weight).whereNotNull().maxOrNull;
    double? avgWeight = sets.map((s) => s.weight).whereNotNull().sum / numSets;
    int minCount = sets.map((s) => s.count).minOrNull ?? 0;
    int maxCount = sets.map((s) => s.count).maxOrNull ?? 0;
    int sumCount = sets.map((s) => s.count).sum;
    double avgCount = sets.isEmpty ? 0 : sumCount / numSets;
    double? maxEorm =
        sets.map((s) => s.eorm(movementDimension)).whereNotNull().maxOrNull;
    double? sumVolume = sets.map((s) => s.volume).whereNotNull().sum;

    return StrengthSessionStats(
      datetime: datetime,
      numSets: numSets,
      maxWeight: maxWeight,
      avgWeight: avgWeight,
      minCount: minCount,
      maxCount: maxCount,
      sumCount: sumCount,
      avgCount: avgCount,
      maxEorm: maxEorm,
      sumVolume: sumVolume,
    );
  }

  factory StrengthSessionStats.fromJson(Map<String, dynamic> json) =>
      _$StrengthSessionStatsFromJson(json);

  DateTime datetime;
  double? maxWeight;
  double? avgWeight;
  int numSets;
  int minCount;
  int maxCount;
  int sumCount;
  double avgCount;
  double? maxEorm;
  double? sumVolume;

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
