// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'metcon_movement_description.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MetconMovementDescription _$MetconMovementDescriptionFromJson(
        Map<String, dynamic> json) =>
    MetconMovementDescription(
      metconMovement: MetconMovement.fromJson(
          json['metcon_movement'] as Map<String, dynamic>),
      movement: Movement.fromJson(json['movement'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$MetconMovementDescriptionToJson(
        MetconMovementDescription instance) =>
    <String, dynamic>{
      'metcon_movement': instance.metconMovement,
      'movement': instance.movement,
    };
