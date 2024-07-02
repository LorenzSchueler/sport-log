// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'metcon_movement.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MetconMovement _$MetconMovementFromJson(Map<String, dynamic> json) =>
    MetconMovement(
      id: const IdConverter().fromJson(json['id'] as String),
      metconId: const IdConverter().fromJson(json['metcon_id'] as String),
      movementId: const IdConverter().fromJson(json['movement_id'] as String),
      movementNumber: (json['movement_number'] as num).toInt(),
      count: (json['count'] as num).toInt(),
      maleWeight: (json['male_weight'] as num?)?.toDouble(),
      femaleWeight: (json['female_weight'] as num?)?.toDouble(),
      distanceUnit:
          $enumDecodeNullable(_$DistanceUnitEnumMap, json['distance_unit']),
      deleted: json['deleted'] as bool,
    );

Map<String, dynamic> _$MetconMovementToJson(MetconMovement instance) =>
    <String, dynamic>{
      'id': const IdConverter().toJson(instance.id),
      'metcon_id': const IdConverter().toJson(instance.metconId),
      'movement_id': const IdConverter().toJson(instance.movementId),
      'movement_number': instance.movementNumber,
      'count': instance.count,
      'male_weight': instance.maleWeight,
      'female_weight': instance.femaleWeight,
      'distance_unit': _$DistanceUnitEnumMap[instance.distanceUnit],
      'deleted': instance.deleted,
    };

const _$DistanceUnitEnumMap = {
  DistanceUnit.m: 'Meter',
  DistanceUnit.km: 'Km',
  DistanceUnit.yd: 'Yard',
  DistanceUnit.ft: 'Foot',
  DistanceUnit.mi: 'Mile',
};
