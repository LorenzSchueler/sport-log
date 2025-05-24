// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cardio_session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CardioSession _$CardioSessionFromJson(Map<String, dynamic> json) =>
    CardioSession(
      id: const IdConverter().fromJson(json['id'] as String),
      movementId: const IdConverter().fromJson(json['movement_id'] as String),
      cardioType: $enumDecode(_$CardioTypeEnumMap, json['cardio_type']),
      datetime: const DateTimeConverter().fromJson(json['datetime'] as String),
      distance: (json['distance'] as num?)?.toInt(),
      ascent: (json['ascent'] as num?)?.toInt(),
      descent: (json['descent'] as num?)?.toInt(),
      time: const OptionalDurationConverter().fromJson(
        (json['time'] as num?)?.toInt(),
      ),
      calories: (json['calories'] as num?)?.toInt(),
      track: (json['track'] as List<dynamic>?)
          ?.map((e) => Position.fromJson(e as Map<String, dynamic>))
          .toList(),
      avgCadence: (json['avg_cadence'] as num?)?.toInt(),
      cadence: const OptionalDurationListConverter().fromJson(
        json['cadence'] as List?,
      ),
      avgHeartRate: (json['avg_heart_rate'] as num?)?.toInt(),
      heartRate: const OptionalDurationListConverter().fromJson(
        json['heart_rate'] as List?,
      ),
      routeId: const OptionalIdConverter().fromJson(
        json['route_id'] as String?,
      ),
      comments: json['comments'] as String?,
      deleted: json['deleted'] as bool,
    );

Map<String, dynamic> _$CardioSessionToJson(CardioSession instance) =>
    <String, dynamic>{
      'id': const IdConverter().toJson(instance.id),
      'user_id': const IdConverter().toJson(instance._userId),
      'movement_id': const IdConverter().toJson(instance.movementId),
      'cardio_type': _$CardioTypeEnumMap[instance.cardioType]!,
      'datetime': const DateTimeConverter().toJson(instance.datetime),
      'distance': instance.distance,
      'ascent': instance.ascent,
      'descent': instance.descent,
      'time': const OptionalDurationConverter().toJson(instance.time),
      'calories': instance.calories,
      'track': instance.track,
      'avg_cadence': instance.avgCadence,
      'cadence': const OptionalDurationListConverter().toJson(instance.cadence),
      'avg_heart_rate': instance.avgHeartRate,
      'heart_rate': const OptionalDurationListConverter().toJson(
        instance.heartRate,
      ),
      'route_id': const OptionalIdConverter().toJson(instance.routeId),
      'comments': instance.comments,
      'deleted': instance.deleted,
    };

const _$CardioTypeEnumMap = {
  CardioType.training: 'Training',
  CardioType.activeRecovery: 'ActiveRecovery',
  CardioType.freetime: 'Freetime',
};
