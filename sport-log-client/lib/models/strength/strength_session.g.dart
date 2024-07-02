// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'strength_session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StrengthSession _$StrengthSessionFromJson(Map<String, dynamic> json) =>
    StrengthSession(
      id: const IdConverter().fromJson(json['id'] as String),
      datetime: const DateTimeConverter().fromJson(json['datetime'] as String),
      movementId: const IdConverter().fromJson(json['movement_id'] as String),
      interval: const OptionalDurationConverter()
          .fromJson((json['interval'] as num?)?.toInt()),
      comments: json['comments'] as String?,
      deleted: json['deleted'] as bool,
    );

Map<String, dynamic> _$StrengthSessionToJson(StrengthSession instance) =>
    <String, dynamic>{
      'id': const IdConverter().toJson(instance.id),
      'user_id': const IdConverter().toJson(instance._userId),
      'datetime': const DateTimeConverter().toJson(instance.datetime),
      'movement_id': const IdConverter().toJson(instance.movementId),
      'interval': const OptionalDurationConverter().toJson(instance.interval),
      'comments': instance.comments,
      'deleted': instance.deleted,
    };
