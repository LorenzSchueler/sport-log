// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'action_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ActionEvent _$ActionEventFromJson(Map<String, dynamic> json) => ActionEvent(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      actionId: json['action_id'] as int,
      datetime: DateTime.parse(json['datetime'] as String),
      enabled: json['enabled'] as bool,
      deleted: json['deleted'] as bool,
    );

Map<String, dynamic> _$ActionEventToJson(ActionEvent instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'action_id': instance.actionId,
      'datetime': instance.datetime.toIso8601String(),
      'enabled': instance.enabled,
      'deleted': instance.deleted,
    };
