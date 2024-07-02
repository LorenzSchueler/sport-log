// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'strength_set.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StrengthSet _$StrengthSetFromJson(Map<String, dynamic> json) => StrengthSet(
      id: const IdConverter().fromJson(json['id'] as String),
      strengthSessionId:
          const IdConverter().fromJson(json['strength_session_id'] as String),
      setNumber: (json['set_number'] as num).toInt(),
      count: (json['count'] as num).toInt(),
      weight: (json['weight'] as num?)?.toDouble(),
      deleted: json['deleted'] as bool,
    );

Map<String, dynamic> _$StrengthSetToJson(StrengthSet instance) =>
    <String, dynamic>{
      'id': const IdConverter().toJson(instance.id),
      'strength_session_id':
          const IdConverter().toJson(instance.strengthSessionId),
      'set_number': instance.setNumber,
      'count': instance.count,
      'weight': instance.weight,
      'deleted': instance.deleted,
    };
