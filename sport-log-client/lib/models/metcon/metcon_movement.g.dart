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
      movementUnit: _$enumDecode(_$MovementUnitEnumMap, json['movement_unit']),
      weight: (json['weight'] as num?)?.toDouble(),
      deleted: json['deleted'] as bool,
    );

Map<String, dynamic> _$MetconMovementToJson(MetconMovement instance) =>
    <String, dynamic>{
      'id': const IdConverter().toJson(instance.id),
      'metcon_id': const IdConverter().toJson(instance.metconId),
      'movement_id': const IdConverter().toJson(instance.movementId),
      'movement_number': instance.movementNumber,
      'count': instance.count,
      'movement_unit': _$MovementUnitEnumMap[instance.movementUnit],
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
