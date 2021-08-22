// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'action_rule.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ActionRule _$ActionRuleFromJson(Map<String, dynamic> json) => ActionRule(
      id: const IdConverter().fromJson(json['id'] as String),
      userId: const IdConverter().fromJson(json['user_id'] as String),
      actionId: const IdConverter().fromJson(json['action_id'] as String),
      weekday: _$enumDecode(_$WeekdayEnumMap, json['weekday']),
      time: const DateTimeConverter().fromJson(json['time'] as String),
      enabled: json['enabled'] as bool,
      deleted: json['deleted'] as bool,
    );

Map<String, dynamic> _$ActionRuleToJson(ActionRule instance) =>
    <String, dynamic>{
      'id': const IdConverter().toJson(instance.id),
      'user_id': const IdConverter().toJson(instance.userId),
      'action_id': const IdConverter().toJson(instance.actionId),
      'weekday': _$WeekdayEnumMap[instance.weekday],
      'time': const DateTimeConverter().toJson(instance.time),
      'enabled': instance.enabled,
      'deleted': instance.deleted,
    };

K _$enumDecode<K, V>(
  Map<K, V> enumValues,
  Object? source, {
  K? unknownValue,
}) {
  if (source == null) {
    throw ArgumentError(
      'A value must be provided. Supported values: '
      '${enumValues.values.join(', ')}',
    );
  }

  return enumValues.entries.singleWhere(
    (e) => e.value == source,
    orElse: () {
      if (unknownValue == null) {
        throw ArgumentError(
          '`$source` is not one of the supported values: '
          '${enumValues.values.join(', ')}',
        );
      }
      return MapEntry(unknownValue, enumValues.values.first);
    },
  ).key;
}

const _$WeekdayEnumMap = {
  Weekday.monday: 'Monday',
  Weekday.tuesday: 'Tuesday',
  Weekday.wednesday: 'Wednesday',
  Weekday.thursday: 'Thursday',
  Weekday.friday: 'Friday',
  Weekday.saturday: 'Saturday',
  Weekday.sunday: 'Sunday',
};
