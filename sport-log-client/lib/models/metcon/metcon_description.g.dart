// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'metcon_description.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MetconDescription _$MetconDescriptionFromJson(Map<String, dynamic> json) =>
    MetconDescription(
      metcon: Metcon.fromJson(json['metcon'] as Map<String, dynamic>),
      moves:
          (json['moves'] as List<dynamic>)
              .map(
                (e) => MetconMovementDescription.fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList(),
      hasReference: json['has_reference'] as bool,
    );

Map<String, dynamic> _$MetconDescriptionToJson(MetconDescription instance) =>
    <String, dynamic>{
      'metcon': instance.metcon,
      'moves': instance.moves,
      'has_reference': instance.hasReference,
    };
