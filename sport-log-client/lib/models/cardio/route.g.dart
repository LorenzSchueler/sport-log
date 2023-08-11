// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'route.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Route _$RouteFromJson(Map<String, dynamic> json) => Route(
      id: const IdConverter().fromJson(json['id'] as String),
      name: json['name'] as String,
      distance: json['distance'] as int?,
      ascent: json['ascent'] as int?,
      descent: json['descent'] as int?,
      track: (json['track'] as List<dynamic>?)
          ?.map((e) => Position.fromJson(e as Map<String, dynamic>))
          .toList(),
      markedPositions: (json['marked_positions'] as List<dynamic>?)
          ?.map((e) => Position.fromJson(e as Map<String, dynamic>))
          .toList(),
      deleted: json['deleted'] as bool,
    );

Map<String, dynamic> _$RouteToJson(Route instance) => <String, dynamic>{
      'id': const IdConverter().toJson(instance.id),
      'user_id': const IdConverter().toJson(instance._userId),
      'name': instance.name,
      'distance': instance.distance,
      'ascent': instance.ascent,
      'descent': instance.descent,
      'track': instance.track,
      'marked_positions': instance.markedPositions,
      'deleted': instance.deleted,
    };
