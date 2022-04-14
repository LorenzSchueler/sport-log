// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'server_version.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ServerVersion _$ServerVersionFromJson(Map<String, dynamic> json) =>
    ServerVersion(
      min: json['min'] as String,
      max: json['max'] as String,
    );

Map<String, dynamic> _$ServerVersionToJson(ServerVersion instance) =>
    <String, dynamic>{
      'min': instance.min,
      'max': instance.max,
    };
