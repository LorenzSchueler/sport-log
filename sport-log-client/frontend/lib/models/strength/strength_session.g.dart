// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'strength_session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StrengthSession _$StrengthSessionFromJson(Map<String, dynamic> json) {
  return StrengthSession(
    id: const IdConverter().fromJson(json['id'] as String),
    userId: const IdConverter().fromJson(json['user_id'] as String),
    datetime: const DateTimeConverter().fromJson(json['datetime'] as String),
    movementId: const IdConverter().fromJson(json['movement_id'] as String),
    movementUnit: _$enumDecode(_$MovementUnitEnumMap, json['movement_unit']),
    interval: json['interval'] as int?,
    comments: json['comments'] as String?,
    deleted: json['deleted'] as bool,
  );
}

Map<String, dynamic> _$StrengthSessionToJson(StrengthSession instance) =>
    <String, dynamic>{
      'id': const IdConverter().toJson(instance.id),
      'user_id': const IdConverter().toJson(instance.userId),
      'datetime': const DateTimeConverter().toJson(instance.datetime),
      'movement_id': const IdConverter().toJson(instance.movementId),
      'movement_unit': _$MovementUnitEnumMap[instance.movementUnit],
      'interval': instance.interval,
      'comments': instance.comments,
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
