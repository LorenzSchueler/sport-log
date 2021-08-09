// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'action.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Action _$ActionFromJson(Map<String, dynamic> json) => Action(
      id: const IdConverter().fromJson(json['id'] as String),
      name: json['name'] as String,
      actionProviderId:
          const IdConverter().fromJson(json['action_provider_id'] as String),
      description: json['description'] as String?,
      createBefore: json['create_before'] as int,
      deleteAfter: json['delete_after'] as int,
      deleted: json['deleted'] as bool,
    );

Map<String, dynamic> _$ActionToJson(Action instance) => <String, dynamic>{
      'id': const IdConverter().toJson(instance.id),
      'name': instance.name,
      'action_provider_id':
          const IdConverter().toJson(instance.actionProviderId),
      'description': instance.description,
      'create_before': instance.createBefore,
      'delete_after': instance.deleteAfter,
      'deleted': instance.deleted,
    };
