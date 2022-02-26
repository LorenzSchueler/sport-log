// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'movement_description.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MovementDescription _$MovementDescriptionFromJson(Map<String, dynamic> json) =>
    MovementDescription(
      movement: Movement.fromJson(json['movement'] as Map<String, dynamic>),
      hasReference: json['has_reference'] as bool,
    );

Map<String, dynamic> _$MovementDescriptionToJson(
        MovementDescription instance) =>
    <String, dynamic>{
      'movement': instance.movement,
      'has_reference': instance.hasReference,
    };
