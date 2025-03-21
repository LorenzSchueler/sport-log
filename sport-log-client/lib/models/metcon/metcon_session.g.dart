// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'metcon_session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MetconSession _$MetconSessionFromJson(Map<String, dynamic> json) =>
    MetconSession(
      id: const IdConverter().fromJson(json['id'] as String),
      metconId: const IdConverter().fromJson(json['metcon_id'] as String),
      datetime: const DateTimeConverter().fromJson(json['datetime'] as String),
      time: const OptionalDurationConverter().fromJson(
        (json['time'] as num?)?.toInt(),
      ),
      rounds: (json['rounds'] as num?)?.toInt(),
      reps: (json['reps'] as num?)?.toInt(),
      rx: json['rx'] as bool,
      comments: json['comments'] as String?,
      deleted: json['deleted'] as bool,
    );

Map<String, dynamic> _$MetconSessionToJson(MetconSession instance) =>
    <String, dynamic>{
      'id': const IdConverter().toJson(instance.id),
      'user_id': const IdConverter().toJson(instance._userId),
      'metcon_id': const IdConverter().toJson(instance.metconId),
      'datetime': const DateTimeConverter().toJson(instance.datetime),
      'time': const OptionalDurationConverter().toJson(instance.time),
      'rounds': instance.rounds,
      'reps': instance.reps,
      'rx': instance.rx,
      'comments': instance.comments,
      'deleted': instance.deleted,
    };
