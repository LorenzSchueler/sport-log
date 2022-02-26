// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'strength_session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StrengthSession _$StrengthSessionFromJson(Map<String, dynamic> json) =>
    StrengthSession(
      id: const IdConverter().fromJson(json['id'] as String),
      userId: const IdConverter().fromJson(json['user_id'] as String),
      datetime: const DateTimeConverter().fromJson(json['datetime'] as String),
      movementId: const IdConverter().fromJson(json['movement_id'] as String),
      interval:
          const OptionalDurationConverter().fromJson(json['interval'] as int?),
      comments: json['comments'] as String?,
      deleted: json['deleted'] as bool,
    )..strengthBlueprintId = const OptionalIdConverter()
        .fromJson(json['strength_blueprint_id'] as String?);

Map<String, dynamic> _$StrengthSessionToJson(StrengthSession instance) =>
    <String, dynamic>{
      'id': const IdConverter().toJson(instance.id),
      'strength_blueprint_id':
          const OptionalIdConverter().toJson(instance.strengthBlueprintId),
      'user_id': const IdConverter().toJson(instance.userId),
      'datetime': const DateTimeConverter().toJson(instance.datetime),
      'movement_id': const IdConverter().toJson(instance.movementId),
      'interval': const OptionalDurationConverter().toJson(instance.interval),
      'comments': instance.comments,
      'deleted': instance.deleted,
    };
