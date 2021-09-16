// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'metcon.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Metcon _$MetconFromJson(Map<String, dynamic> json) {
  return Metcon(
    id: const IdConverter().fromJson(json['id'] as String),
    userId: const OptionalIdConverter().fromJson(json['user_id'] as String?),
    name: json['name'] as String?,
    metconType: _$enumDecode(_$MetconTypeEnumMap, json['metcon_type']),
    rounds: json['rounds'] as int?,
    timecap: const DurationConverter().fromJson(json['timecap'] as int?),
    description: json['description'] as String?,
    deleted: json['deleted'] as bool,
  );
}

Map<String, dynamic> _$MetconToJson(Metcon instance) => <String, dynamic>{
      'id': const IdConverter().toJson(instance.id),
      'user_id': const OptionalIdConverter().toJson(instance.userId),
      'name': instance.name,
      'metcon_type': _$MetconTypeEnumMap[instance.metconType],
      'rounds': instance.rounds,
      'timecap': const DurationConverter().toJson(instance.timecap),
      'description': instance.description,
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

const _$MetconTypeEnumMap = {
  MetconType.amrap: 'Amrap',
  MetconType.emom: 'Emom',
  MetconType.forTime: 'ForTime',
};
