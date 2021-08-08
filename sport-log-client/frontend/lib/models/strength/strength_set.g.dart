// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'strength_set.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StrengthSet _$StrengthSetFromJson(Map<String, dynamic> json) => StrengthSet(
      id: json['id'] as int,
      strengthSessionId: json['strength_session_id'] as int,
      setNumber: json['set_number'] as int,
      count: json['count'] as int,
      weight: (json['weight'] as num?)?.toDouble(),
      deleted: json['deleted'] as bool,
    );

Map<String, dynamic> _$StrengthSetToJson(StrengthSet instance) =>
    <String, dynamic>{
      'id': instance.id,
      'strength_session_id': instance.strengthSessionId,
      'set_number': instance.setNumber,
      'count': instance.count,
      'weight': instance.weight,
      'deleted': instance.deleted,
    };
