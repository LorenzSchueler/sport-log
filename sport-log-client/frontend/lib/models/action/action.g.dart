// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'action.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Action _$ActionFromJson(Map<String, dynamic> json) => Action(
      id: json['id'] as int,
      name: json['name'] as String,
      actionProviderId: json['action_provider_id'] as int,
      description: json['description'] as String?,
      createBefore: json['create_before'] as int,
      deleteAfter: json['delete_after'] as int,
    );

Map<String, dynamic> _$ActionToJson(Action instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'action_provider_id': instance.actionProviderId,
      'description': instance.description,
      'create_before': instance.createBefore,
      'delete_after': instance.deleteAfter,
    };
