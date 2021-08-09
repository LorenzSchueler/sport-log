// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'platform.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Platform _$PlatformFromJson(Map<String, dynamic> json) => Platform(
      id: const IdConverter().fromJson(json['id'] as String),
      name: json['name'] as String,
      deleted: json['deleted'] as bool,
    );

Map<String, dynamic> _$PlatformToJson(Platform instance) => <String, dynamic>{
      'id': const IdConverter().toJson(instance.id),
      'name': instance.name,
      'deleted': instance.deleted,
    };
