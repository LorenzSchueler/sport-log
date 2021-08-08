// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'platform_credential.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlatformCredential _$PlatformCredentialFromJson(Map<String, dynamic> json) =>
    PlatformCredential(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      platformId: json['platform_id'] as int,
      username: json['username'] as String,
      password: json['password'] as String,
    );

Map<String, dynamic> _$PlatformCredentialToJson(PlatformCredential instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'platform_id': instance.platformId,
      'username': instance.username,
      'password': instance.password,
    };
