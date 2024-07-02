// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'metcon.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Metcon _$MetconFromJson(Map<String, dynamic> json) => Metcon._(
      id: const IdConverter().fromJson(json['id'] as String),
      userId: const OptionalIdConverter().fromJson(json['user_id'] as String?),
      name: json['name'] as String,
      metconType: $enumDecode(_$MetconTypeEnumMap, json['metcon_type']),
      rounds: (json['rounds'] as num?)?.toInt(),
      timecap: const OptionalDurationConverter()
          .fromJson((json['timecap'] as num?)?.toInt()),
      description: json['description'] as String?,
      deleted: json['deleted'] as bool,
    );

Map<String, dynamic> _$MetconToJson(Metcon instance) => <String, dynamic>{
      'id': const IdConverter().toJson(instance.id),
      'user_id': const OptionalIdConverter().toJson(instance.userId),
      'name': instance.name,
      'metcon_type': _$MetconTypeEnumMap[instance.metconType]!,
      'rounds': instance.rounds,
      'timecap': const OptionalDurationConverter().toJson(instance.timecap),
      'description': instance.description,
      'deleted': instance.deleted,
    };

const _$MetconTypeEnumMap = {
  MetconType.amrap: 'Amrap',
  MetconType.emom: 'Emom',
  MetconType.forTime: 'ForTime',
};
