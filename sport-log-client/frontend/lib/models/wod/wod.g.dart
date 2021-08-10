// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wod.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Wod _$WodFromJson(Map<String, dynamic> json) {
  return Wod(
    id: const IdConverter().fromJson(json['id'] as String),
    userId: const IdConverter().fromJson(json['user_id'] as String),
    date: DateTime.parse(json['date'] as String),
    description: json['description'] as String?,
    deleted: json['deleted'] as bool,
  );
}

Map<String, dynamic> _$WodToJson(Wod instance) => <String, dynamic>{
      'id': const IdConverter().toJson(instance.id),
      'user_id': const IdConverter().toJson(instance.userId),
      'date': instance.date.toIso8601String(),
      'description': instance.description,
      'deleted': instance.deleted,
    };
