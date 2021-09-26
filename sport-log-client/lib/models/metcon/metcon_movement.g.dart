// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'metcon_movement.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MetconMovement _$MetconMovementFromJson(Map<String, dynamic> json) {
  return MetconMovement(
    id: const IdConverter().fromJson(json['id'] as String),
    metconId: const IdConverter().fromJson(json['metcon_id'] as String),
    movementId: const IdConverter().fromJson(json['movement_id'] as String),
    movementNumber: json['movement_number'] as int,
    count: json['count'] as int,
    weight: (json['weight'] as num?)?.toDouble(),
    distanceUnit:
        _$enumDecodeNullable(_$DistanceUnitEnumMap, json['distance_unit']),
    deleted: json['deleted'] as bool,
  );
}

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

K? _$enumDecodeNullable<K, V>(
  Map<K, V> enumValues,
  dynamic source, {
  K? unknownValue,
}) {
  if (source == null) {
    return null;
  }
  return _$enumDecode<K, V>(enumValues, source, unknownValue: unknownValue);
}

const _$DistanceUnitEnumMap = {
  DistanceUnit.m: 'm',
  DistanceUnit.km: 'km',
  DistanceUnit.yards: 'yards',
  DistanceUnit.feet: 'feet',
  DistanceUnit.inches: 'inches',
};
