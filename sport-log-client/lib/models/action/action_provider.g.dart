// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'action_provider.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ActionProvider _$ActionProviderFromJson(Map<String, dynamic> json) =>
    ActionProvider._(
      id: const IdConverter().fromJson(json['id'] as String),
      name: json['name'] as String,
      platformId: const IdConverter().fromJson(json['platform_id'] as String),
      description: json['description'] as String?,
      deleted: json['deleted'] as bool,
    );

Map<String, dynamic> _$ActionProviderToJson(ActionProvider instance) =>
    <String, dynamic>{
      'id': const IdConverter().toJson(instance.id),
      'name': instance.name,
      'platform_id': const IdConverter().toJson(instance.platformId),
      'description': instance.description,
      'deleted': instance.deleted,
    };
