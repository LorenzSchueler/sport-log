// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cardio_session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CardioSession _$CardioSessionFromJson(Map<String, dynamic> json) =>
    CardioSession(
      id: const IdConverter().fromJson(json['id'] as String),
      userId: const IdConverter().fromJson(json['user_id'] as String),
      movementId: const IdConverter().fromJson(json['movement_id'] as String),
      cardioType: _$enumDecode(_$CardioTypeEnumMap, json['cardio_type']),
      datetime: const DateTimeConverter().fromJson(json['datetime'] as String),
      distance: json['distance'] as int?,
      ascent: json['ascent'] as int?,
      descent: json['descent'] as int?,
      time: json['time'] as int?,
      calories: json['calories'] as int?,
      track: (json['track'] as List<dynamic>?)
          ?.map((e) => Position.fromJson(e as Map<String, dynamic>))
          .toList(),
      avgCycles: json['avg_cycles'] as int?,
      cycles: (json['cycles'] as List<dynamic>?)
          ?.map((e) => (e as num).toDouble())
          .toList(),
      avgHeartRate: json['avg_heart_rate'] as int?,
      heartRate: (json['heart_rate'] as List<dynamic>?)
          ?.map((e) => (e as num).toDouble())
          .toList(),
      routeId:
          const OptionalIdConverter().fromJson(json['route_id'] as String?),
      comments: json['comments'] as String?,
      deleted: json['deleted'] as bool,
    );

Map<String, dynamic> _$CardioSessionToJson(CardioSession instance) =>
    <String, dynamic>{
      'id': const IdConverter().toJson(instance.id),
      'user_id': const IdConverter().toJson(instance.userId),
      'movement_id': const IdConverter().toJson(instance.movementId),
      'cardio_type': _$CardioTypeEnumMap[instance.cardioType],
      'datetime': const DateTimeConverter().toJson(instance.datetime),
      'distance': instance.distance,
      'ascent': instance.ascent,
      'descent': instance.descent,
      'time': instance.time,
      'calories': instance.calories,
      'track': instance.track,
      'avg_cycles': instance.avgCycles,
      'cycles': instance.cycles,
      'avg_heart_rate': instance.avgHeartRate,
      'heart_rate': instance.heartRate,
      'route_id': const OptionalIdConverter().toJson(instance.routeId),
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

const _$CardioTypeEnumMap = {
  CardioType.training: 'Training',
  CardioType.activeRecovery: 'ActiveRecovery',
  CardioType.freetime: 'Freetime',
};
