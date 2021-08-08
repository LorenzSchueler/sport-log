// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'metcon_movement.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MetconMovement _$MetconMovementFromJson(Map<String, dynamic> json) =>
    MetconMovement(
      id: json['id'] as int,
      metconId: json['metcon_id'] as int,
      movementId: json['movement_id'] as int,
      movementNumber: json['movement_number'] as int,
      count: json['count'] as int,
      unit: _$enumDecode(_$MovementUnitEnumMap, json['unit']),
      weight: (json['weight'] as num?)?.toDouble(),
      deleted: json['deleted'] as bool,
    );

Map<String, dynamic> _$MetconMovementToJson(MetconMovement instance) =>
    <String, dynamic>{
      'id': instance.id,
      'metcon_id': instance.metconId,
      'movement_id': instance.movementId,
      'movement_number': instance.movementNumber,
      'count': instance.count,
      'unit': _$MovementUnitEnumMap[instance.unit],
      'weight': instance.weight,
      'deleted': instance.deleted,
    };

K _$enumDecode<K, V>(
  Map<K, V> enumValues,
  Object? source, {
  K? unknownValue,
}) {
  if (source == null) {
    throw ArgumentError(
      'A value must be provided. Supported values: '
      '${enumValues.values.join(', ')}',
    );
  }

  return enumValues.entries.singleWhere(
    (e) => e.value == source,
    orElse: () {
      if (unknownValue == null) {
        throw ArgumentError(
          '`$source` is not one of the supported values: '
          '${enumValues.values.join(', ')}',
        );
      }
      return MapEntry(unknownValue, enumValues.values.first);
    },
  ).key;
}

const _$MovementUnitEnumMap = {
  MovementUnit.reps: 'Reps',
  MovementUnit.cal: 'Cal',
  MovementUnit.meter: 'Meter',
  MovementUnit.km: 'Km',
  MovementUnit.yard: 'Yard',
  MovementUnit.foot: 'Foot',
  MovementUnit.mile: 'Mile',
};
