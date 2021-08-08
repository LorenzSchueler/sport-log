// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'route.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Route _$RouteFromJson(Map<String, dynamic> json) => Route(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      name: json['name'] as String,
      distance: json['distance'] as int,
      ascent: json['ascent'] as int?,
      descent: json['descent'] as int?,
      track: (json['track'] as List<dynamic>?)
          ?.map((e) => Position.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$RouteToJson(Route instance) => <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'name': instance.name,
      'distance': instance.distance,
      'ascent': instance.ascent,
      'descent': instance.descent,
      'track': instance.track,
    };

NewRoute _$NewRouteFromJson(Map<String, dynamic> json) => NewRoute(
      userId: json['user_id'] as int,
      name: json['name'] as String,
      distance: json['distance'] as int,
      ascent: json['ascent'] as int?,
      descent: json['descent'] as int?,
      track: (json['track'] as List<dynamic>?)
          ?.map((e) => Position.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$NewRouteToJson(NewRoute instance) => <String, dynamic>{
      'user_id': instance.userId,
      'name': instance.name,
      'distance': instance.distance,
      'ascent': instance.ascent,
      'descent': instance.descent,
      'track': instance.track,
    };
