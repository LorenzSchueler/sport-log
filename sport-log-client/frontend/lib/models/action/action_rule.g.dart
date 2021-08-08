// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'action_rule.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ActionRule _$ActionRuleFromJson(Map<String, dynamic> json) => ActionRule(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      actionId: json['action_id'] as int,
      weekday: _$enumDecode(_$WeekdayEnumMap, json['weekday']),
      time: DateTime.parse(json['time'] as String),
      enabled: json['enabled'] as bool,
    );

Map<String, dynamic> _$ActionRuleToJson(ActionRule instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'action_id': instance.actionId,
      'weekday': _$WeekdayEnumMap[instance.weekday],
      'time': instance.time.toIso8601String(),
      'enabled': instance.enabled,
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
  Weekday.monday: 'monday',
  Weekday.tuesday: 'tuesday',
  Weekday.wednesday: 'wednesday',
  Weekday.thursday: 'thursday',
  Weekday.friday: 'friday',
  Weekday.saturday: 'saturday',
  Weekday.sunday: 'sunday',
};
