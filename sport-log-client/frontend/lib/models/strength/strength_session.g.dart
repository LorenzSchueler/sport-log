// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'strength_session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StrengthSession _$StrengthSessionFromJson(Map<String, dynamic> json) =>
    StrengthSession(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      datetime: DateTime.parse(json['datetime'] as String),
      movementId: json['movement_id'] as int,
      movementUnit: _$enumDecode(_$MovementUnitEnumMap, json['movement_unit']),
      interval: json['interval'] as int?,
      comments: json['comments'] as String?,
      deleted: json['deleted'] as bool,
    );

Map<String, dynamic> _$StrengthSessionToJson(StrengthSession instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'datetime': instance.datetime.toIso8601String(),
      'movement_id': instance.movementId,
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
