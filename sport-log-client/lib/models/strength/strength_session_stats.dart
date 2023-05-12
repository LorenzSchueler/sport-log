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
    final numSets = sets.length;
    final maxWeight = sets.map((s) => s.weight).whereNotNull().maxOrNull;
    final avgWeight = sets.map((s) => s.weight).whereNotNull().sum / numSets;
    final minCount = sets.map((s) => s.count).minOrNull ?? 0;
    final maxCount = sets.map((s) => s.count).maxOrNull ?? 0;
    final sumCount = sets.map((s) => s.count).sum;
    final avgCount = sets.isEmpty ? 0.0 : sumCount / numSets;
    final maxEorm =
        sets.map((s) => s.eorm(movementDimension)).whereNotNull().maxOrNull;
    final sumVolume = sets.map((s) => s.volume).whereNotNull().sum;

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
    return switch (dimension) {
      MovementDimension.reps => [
          if (maxEorm != null) '1RM: ${formatWeight(maxEorm!)}',
          if (sumVolume != null) 'Vol: ${formatWeight(sumVolume!)}',
          if (maxWeight != null) 'Max Weight: ${formatWeight(maxWeight!)}',
          'Avg Reps: ${avgCount.toStringAsFixed(1)}',
        ].join(' • '),
      MovementDimension.time =>
        'Best time: ${Duration(milliseconds: minCount).formatMsMill}',
      MovementDimension.distance => 'Best distance: $maxCount m',
      MovementDimension.energy => 'Total energy: $sumCount cal',
    };
  }
}
