// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'action_provider_description.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ActionProviderDescription _$ActionProviderDescriptionFromJson(
  Map<String, dynamic> json,
) => ActionProviderDescription(
  actionProvider: ActionProvider.fromJson(
    json['action_provider'] as Map<String, dynamic>,
  ),
  actions: (json['actions'] as List<dynamic>)
      .map((e) => Action.fromJson(e as Map<String, dynamic>))
      .toList(),
  actionRules: (json['action_rules'] as List<dynamic>)
      .map((e) => ActionRule.fromJson(e as Map<String, dynamic>))
      .toList(),
  actionEvents: (json['action_events'] as List<dynamic>)
      .map((e) => ActionEvent.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$ActionProviderDescriptionToJson(
  ActionProviderDescription instance,
) => <String, dynamic>{
  'action_provider': instance.actionProvider,
  'actions': instance.actions,
  'action_rules': instance.actionRules,
  'action_events': instance.actionEvents,
};
