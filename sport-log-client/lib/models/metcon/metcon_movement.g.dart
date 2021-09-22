// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'metcon_movement.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MetconMovement _$MetconMovementFromJson(Map<String, dynamic> json) {
  return MetconMovement(
    id: const IdConverter().fromJson(json['id'] as String),
    metconId: const IdConverter().fromJson(json['metcon_id'] as String),
    movementId: const IdConverter().fromJson(json['movement_id'] as String),
    movementNumber: json['movement_number'] as int,
    count: json['count'] as int,
    weight: (json['weight'] as num?)?.toDouble(),
    deleted: json['deleted'] as bool,
  );
}

Map<String, dynamic> _$MetconMovementToJson(MetconMovement instance) =>
    <String, dynamic>{
      'id': const IdConverter().toJson(instance.id),
      'metcon_id': const IdConverter().toJson(instance.metconId),
      'movement_id': const IdConverter().toJson(instance.movementId),
      'movement_number': instance.movementNumber,
      'count': instance.count,
      'weight': instance.weight,
      'deleted': instance.deleted,
    };
