// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cardio_session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CardioSession _$CardioSessionFromJson(Map<String, dynamic> json) =>
    CardioSession(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      movementId: json['movement_id'] as int,
      cardioType: _$enumDecode(_$CardioTypeEnumMap, json['cardio_type']),
      datetime: DateTime.parse(json['datetime'] as String),
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
      routeId: json['route_id'] as int?,
      comments: json['comments'] as String?,
    );

Map<String, dynamic> _$CardioSessionToJson(CardioSession instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'movement_id': instance.movementId,
      'cardio_type': _$CardioTypeEnumMap[instance.cardioType],
      'datetime': instance.datetime.toIso8601String(),
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
      'route_id': instance.routeId,
      'comments': instance.comments,
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

NewCardioSession _$NewCardioSessionFromJson(Map<String, dynamic> json) =>
    NewCardioSession(
      userId: json['user_id'] as int,
      movementId: json['movement_id'] as int,
      cardioType: _$enumDecode(_$CardioTypeEnumMap, json['cardio_type']),
      datetime: DateTime.parse(json['datetime'] as String),
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
      routeId: json['route_id'] as int?,
      comments: json['comments'] as String?,
    );

Map<String, dynamic> _$NewCardioSessionToJson(NewCardioSession instance) =>
    <String, dynamic>{
      'user_id': instance.userId,
      'movement_id': instance.movementId,
      'cardio_type': _$CardioTypeEnumMap[instance.cardioType],
      'datetime': instance.datetime.toIso8601String(),
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
      'route_id': instance.routeId,
      'comments': instance.comments,
    };
