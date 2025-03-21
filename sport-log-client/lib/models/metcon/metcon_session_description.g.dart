// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'metcon_session_description.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MetconSessionDescription _$MetconSessionDescriptionFromJson(
  Map<String, dynamic> json,
) => MetconSessionDescription(
  metconSession: MetconSession.fromJson(
    json['metcon_session'] as Map<String, dynamic>,
  ),
  metconDescription: MetconDescription.fromJson(
    json['metcon_description'] as Map<String, dynamic>,
  ),
);

Map<String, dynamic> _$MetconSessionDescriptionToJson(
  MetconSessionDescription instance,
) => <String, dynamic>{
  'metcon_session': instance.metconSession,
  'metcon_description': instance.metconDescription,
};
