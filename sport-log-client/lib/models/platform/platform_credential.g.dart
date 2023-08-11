// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'platform_credential.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlatformCredential _$PlatformCredentialFromJson(Map<String, dynamic> json) =>
    PlatformCredential(
      id: const IdConverter().fromJson(json['id'] as String),
      platformId: const IdConverter().fromJson(json['platform_id'] as String),
      username: json['username'] as String,
      password: json['password'] as String,
      deleted: json['deleted'] as bool,
    );

Map<String, dynamic> _$PlatformCredentialToJson(PlatformCredential instance) =>
    <String, dynamic>{
      'id': const IdConverter().toJson(instance.id),
      'user_id': const IdConverter().toJson(instance._userId),
      'platform_id': const IdConverter().toJson(instance.platformId),
      'username': instance.username,
      'password': instance.password,
      'deleted': instance.deleted,
    };
