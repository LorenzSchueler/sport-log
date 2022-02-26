// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'strength_session_description.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StrengthSessionDescription _$StrengthSessionDescriptionFromJson(
        Map<String, dynamic> json) =>
    StrengthSessionDescription(
      session:
          StrengthSession.fromJson(json['session'] as Map<String, dynamic>),
      movement: Movement.fromJson(json['movement'] as Map<String, dynamic>),
      sets: (json['sets'] as List<dynamic>)
          .map((e) => StrengthSet.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$StrengthSessionDescriptionToJson(
        StrengthSessionDescription instance) =>
    <String, dynamic>{
      'session': instance.session,
      'movement': instance.movement,
      'sets': instance.sets,
    };
