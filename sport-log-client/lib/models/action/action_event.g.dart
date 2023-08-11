// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'action_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ActionEvent _$ActionEventFromJson(Map<String, dynamic> json) => ActionEvent(
      id: const IdConverter().fromJson(json['id'] as String),
      actionId: const IdConverter().fromJson(json['action_id'] as String),
      datetime: const DateTimeConverter().fromJson(json['datetime'] as String),
      arguments: json['arguments'] as String?,
      enabled: json['enabled'] as bool,
      deleted: json['deleted'] as bool,
    );

Map<String, dynamic> _$ActionEventToJson(ActionEvent instance) =>
    <String, dynamic>{
      'id': const IdConverter().toJson(instance.id),
      'user_id': const IdConverter().toJson(instance._userId),
      'action_id': const IdConverter().toJson(instance.actionId),
      'datetime': const DateTimeConverter().toJson(instance.datetime),
      'arguments': instance.arguments,
      'enabled': instance.enabled,
      'deleted': instance.deleted,
    };
