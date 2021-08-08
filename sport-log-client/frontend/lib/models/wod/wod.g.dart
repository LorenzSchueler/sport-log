// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wod.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Wod _$WodFromJson(Map<String, dynamic> json) => Wod(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      date: DateTime.parse(json['date'] as String),
      description: json['description'] as String?,
    );

Map<String, dynamic> _$WodToJson(Wod instance) => <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'date': instance.date.toIso8601String(),
      'description': instance.description,
    };
