// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'action_rule.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ActionRule _$ActionRuleFromJson(Map<String, dynamic> json) => ActionRule(
  id: const IdConverter().fromJson(json['id'] as String),
  actionId: const IdConverter().fromJson(json['action_id'] as String),
  weekday: $enumDecode(_$WeekdayEnumMap, json['weekday']),
  time: const DateTimeConverter().fromJson(json['time'] as String),
  arguments: json['arguments'] as String?,
  enabled: json['enabled'] as bool,
  deleted: json['deleted'] as bool,
);

Map<String, dynamic> _$ActionRuleToJson(ActionRule instance) =>
    <String, dynamic>{
      'id': const IdConverter().toJson(instance.id),
      'user_id': const IdConverter().toJson(instance._userId),
      'action_id': const IdConverter().toJson(instance.actionId),
      'weekday': _$WeekdayEnumMap[instance.weekday]!,
      'time': const DateTimeConverter().toJson(instance.time),
      'arguments': instance.arguments,
      'enabled': instance.enabled,
      'deleted': instance.deleted,
    };

const _$WeekdayEnumMap = {
  Weekday.monday: 'Monday',
  Weekday.tuesday: 'Tuesday',
  Weekday.wednesday: 'Wednesday',
  Weekday.thursday: 'Thursday',
  Weekday.friday: 'Friday',
  Weekday.saturday: 'Saturday',
  Weekday.sunday: 'Sunday',
};
