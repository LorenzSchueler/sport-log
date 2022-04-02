// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'platform_description.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlatformDescription _$PlatformDescriptionFromJson(Map<String, dynamic> json) =>
    PlatformDescription(
      platform: Platform.fromJson(json['platform'] as Map<String, dynamic>),
      platformCredential: json['platform_credential'] == null
          ? null
          : PlatformCredential.fromJson(
              json['platform_credential'] as Map<String, dynamic>),
      actionProviders: (json['action_providers'] as List<dynamic>)
          .map((e) => ActionProvider.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$PlatformDescriptionToJson(
        PlatformDescription instance) =>
    <String, dynamic>{
      'platform': instance.platform,
      'platform_credential': instance.platformCredential,
      'action_providers': instance.actionProviders,
    };
