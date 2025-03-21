// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cardio_session_description.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CardioSessionDescription _$CardioSessionDescriptionFromJson(
  Map<String, dynamic> json,
) => CardioSessionDescription(
  cardioSession: CardioSession.fromJson(
    json['cardio_session'] as Map<String, dynamic>,
  ),
  route:
      json['route'] == null
          ? null
          : Route.fromJson(json['route'] as Map<String, dynamic>),
  movement: Movement.fromJson(json['movement'] as Map<String, dynamic>),
);

Map<String, dynamic> _$CardioSessionDescriptionToJson(
  CardioSessionDescription instance,
) => <String, dynamic>{
  'cardio_session': instance.cardioSession,
  'route': instance.route,
  'movement': instance.movement,
};
