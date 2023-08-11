// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'action.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Action _$ActionFromJson(Map<String, dynamic> json) => Action._(
      id: const IdConverter().fromJson(json['id'] as String),
      name: json['name'] as String,
      actionProviderId:
          const IdConverter().fromJson(json['action_provider_id'] as String),
      description: json['description'] as String?,
      deleted: json['deleted'] as bool,
    );

Map<String, dynamic> _$ActionToJson(Action instance) => <String, dynamic>{
      'id': const IdConverter().toJson(instance.id),
      'name': instance.name,
      'action_provider_id':
          const IdConverter().toJson(instance.actionProviderId),
      'description': instance.description,
      'deleted': instance.deleted,
    };
