// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'metcon_session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MetconSession _$MetconSessionFromJson(Map<String, dynamic> json) {
  return MetconSession(
    id: const IdConverter().fromJson(json['id'] as String),
    userId: const IdConverter().fromJson(json['user_id'] as String),
    metconId: const IdConverter().fromJson(json['metcon_id'] as String),
    datetime: DateTime.parse(json['datetime'] as String),
    time: json['time'] as int?,
    rounds: json['rounds'] as int?,
    reps: json['reps'] as int?,
    rx: json['rx'] as bool,
    comments: json['comments'] as String?,
    deleted: json['deleted'] as bool,
  );
}

Map<String, dynamic> _$MetconSessionToJson(MetconSession instance) =>
    <String, dynamic>{
      'id': const IdConverter().toJson(instance.id),
      'user_id': const IdConverter().toJson(instance.userId),
      'metcon_id': const IdConverter().toJson(instance.metconId),
      'datetime': instance.datetime.toIso8601String(),
      'time': instance.time,
      'rounds': instance.rounds,
      'reps': instance.reps,
      'rx': instance.rx,
      'comments': instance.comments,
      'deleted': instance.deleted,
    };
