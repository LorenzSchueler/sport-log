// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'position.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Position _$PositionFromJson(Map<String, dynamic> json) => Position(
      longitude: (json['lo'] as num).toDouble(),
      latitude: (json['la'] as num).toDouble(),
      elevation: json['e'] as int,
      distance: json['d'] as int,
      time: json['t'] as int,
    );

Map<String, dynamic> _$PositionToJson(Position instance) => <String, dynamic>{
      'lo': instance.longitude,
      'la': instance.latitude,
      'e': instance.elevation,
      'd': instance.distance,
      't': instance.time,
    };
