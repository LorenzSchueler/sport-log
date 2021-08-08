// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'metcon_session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MetconSession _$MetconSessionFromJson(Map<String, dynamic> json) =>
    MetconSession(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      metconId: json['metcon_id'] as int,
      datetime: DateTime.parse(json['datetime'] as String),
      time: json['time'] as int?,
      rounds: json['rounds'] as int?,
      reps: json['reps'] as int?,
      rx: json['rx'] as bool,
      comments: json['comments'] as String?,
    );

Map<String, dynamic> _$MetconSessionToJson(MetconSession instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'metcon_id': instance.metconId,
      'datetime': instance.datetime.toIso8601String(),
      'time': instance.time,
      'rounds': instance.rounds,
      'reps': instance.reps,
      'rx': instance.rx,
      'comments': instance.comments,
    };
