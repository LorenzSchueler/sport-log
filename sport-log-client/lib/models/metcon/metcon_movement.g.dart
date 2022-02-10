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
      movementNumber: json['movement_number'] as int,
      count: json['count'] as int,
      weight: (json['weight'] as num?)?.toDouble(),
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
      'weight': instance.weight,
      'distance_unit': _$DistanceUnitEnumMap[instance.distanceUnit],
      'deleted': instance.deleted,
    };

const _$DistanceUnitEnumMap = {
  DistanceUnit.m: 'Meter',
  DistanceUnit.km: 'Km',
  DistanceUnit.yards: 'Yard',
  DistanceUnit.feet: 'Foot',
  DistanceUnit.miles: 'Mile',
};
