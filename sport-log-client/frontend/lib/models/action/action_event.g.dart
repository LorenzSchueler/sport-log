// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'action_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ActionEvent _$ActionEventFromJson(Map<String, dynamic> json) => ActionEvent(
      id: const IdConverter().fromJson(json['id'] as String),
      userId: const IdConverter().fromJson(json['user_id'] as String),
      actionId: const IdConverter().fromJson(json['action_id'] as String),
      datetime: DateTime.parse(json['datetime'] as String),
      enabled: json['enabled'] as bool,
      deleted: json['deleted'] as bool,
    );

Map<String, dynamic> _$ActionEventToJson(ActionEvent instance) =>
    <String, dynamic>{
      'id': const IdConverter().toJson(instance.id),
      'user_id': const IdConverter().toJson(instance.userId),
      'action_id': const IdConverter().toJson(instance.actionId),
      'datetime': instance.datetime.toIso8601String(),
      'enabled': instance.enabled,
      'deleted': instance.deleted,
    };
