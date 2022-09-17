// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'strength_session_stats.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StrengthSessionStats _$StrengthSessionStatsFromJson(
        Map<String, dynamic> json) =>
    StrengthSessionStats(
      datetime: DateTime.parse(json['datetime'] as String),
      numSets: json['num_sets'] as int,
      maxWeight: (json['max_weight'] as num?)?.toDouble(),
      avgWeight: (json['avg_weight'] as num?)?.toDouble(),
      minCount: json['min_count'] as int,
      maxCount: json['max_count'] as int,
      sumCount: json['sum_count'] as int,
      avgCount: (json['avg_count'] as num).toDouble(),
      maxEorm: (json['max_eorm'] as num?)?.toDouble(),
      sumVolume: (json['sum_volume'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$StrengthSessionStatsToJson(
        StrengthSessionStats instance) =>
    <String, dynamic>{
      'datetime': instance.datetime.toIso8601String(),
      'max_weight': instance.maxWeight,
      'avg_weight': instance.avgWeight,
      'num_sets': instance.numSets,
      'min_count': instance.minCount,
      'max_count': instance.maxCount,
      'sum_count': instance.sumCount,
      'avg_count': instance.avgCount,
      'max_eorm': instance.maxEorm,
      'sum_volume': instance.sumVolume,
    };
