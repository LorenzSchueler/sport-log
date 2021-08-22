// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wod.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Wod _$WodFromJson(Map<String, dynamic> json) => Wod(
      id: const IdConverter().fromJson(json['id'] as String),
      userId: const IdConverter().fromJson(json['user_id'] as String),
      date: const DateConverter().fromJson(json['date'] as String),
      description: json['description'] as String?,
      deleted: json['deleted'] as bool,
    );

Map<String, dynamic> _$WodToJson(Wod instance) => <String, dynamic>{
      'id': const IdConverter().toJson(instance.id),
      'user_id': const IdConverter().toJson(instance.userId),
      'date': const DateConverter().toJson(instance.date),
      'description': instance.description,
      'deleted': instance.deleted,
    };
