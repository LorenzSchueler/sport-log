// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'movement.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Movement _$MovementFromJson(Map<String, dynamic> json) => Movement._(
      id: const IdConverter().fromJson(json['id'] as String),
      userId: const OptionalIdConverter().fromJson(json['user_id'] as String?),
      name: json['name'] as String,
      description: json['description'] as String?,
      cardio: json['cardio'] as bool,
      deleted: json['deleted'] as bool,
      dimension:
          $enumDecode(_$MovementDimensionEnumMap, json['movement_dimension']),
    );

Map<String, dynamic> _$MovementToJson(Movement instance) => <String, dynamic>{
      'id': const IdConverter().toJson(instance.id),
      'user_id': const OptionalIdConverter().toJson(instance.userId),
      'name': instance.name,
      'description': instance.description,
      'cardio': instance.cardio,
      'deleted': instance.deleted,
      'movement_dimension': _$MovementDimensionEnumMap[instance.dimension]!,
    };

const _$MovementDimensionEnumMap = {
  MovementDimension.reps: 'Reps',
  MovementDimension.time: 'Time',
  MovementDimension.distance: 'Distance',
  MovementDimension.energy: 'Energy',
};
