// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'position.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Position _$PositionFromJson(Map<String, dynamic> json) => Position(
  longitude: (json['lo'] as num).toDouble(),
  latitude: (json['la'] as num).toDouble(),
  elevation: (json['e'] as num).toDouble(),
  distance: (json['d'] as num).toDouble(),
  time: const DurationConverter().fromJson((json['t'] as num).toInt()),
);

Map<String, dynamic> _$PositionToJson(Position instance) => <String, dynamic>{
  'lo': instance.longitude,
  'la': instance.latitude,
  'e': instance.elevation,
  'd': instance.distance,
  't': const DurationConverter().toJson(instance.time),
};
