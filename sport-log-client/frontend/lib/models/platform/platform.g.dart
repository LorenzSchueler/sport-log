// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'platform.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Platform _$PlatformFromJson(Map<String, dynamic> json) => Platform(
      id: json['id'] as int,
      name: json['name'] as String,
    );

Map<String, dynamic> _$PlatformToJson(Platform instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
    };

NewPlatform _$NewPlatformFromJson(Map<String, dynamic> json) => NewPlatform(
      name: json['name'] as String,
    );

Map<String, dynamic> _$NewPlatformToJson(NewPlatform instance) =>
    <String, dynamic>{
      'name': instance.name,
    };
