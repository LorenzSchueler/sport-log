// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'movement.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Movement _$MovementFromJson(Map<String, dynamic> json) => Movement(
      id: json['id'] as int,
      userId: json['user_id'] as int?,
      name: json['name'] as String,
      description: json['description'] as String?,
      category: _$enumDecode(_$MovementCategoryEnumMap, json['category']),
      deleted: json['deleted'] as bool,
    );

Map<String, dynamic> _$MovementToJson(Movement instance) => <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'name': instance.name,
      'description': instance.description,
      'category': _$MovementCategoryEnumMap[instance.category],
      'deleted': instance.deleted,
    };

K _$enumDecode<K, V>(
  Map<K, V> enumValues,
  Object? source, {
  K? unknownValue,
}) {
  if (source == null) {
    throw ArgumentError(
      'A value must be provided. Supported values: '
      '${enumValues.values.join(', ')}',
    );
  }

  return enumValues.entries.singleWhere(
    (e) => e.value == source,
    orElse: () {
      if (unknownValue == null) {
        throw ArgumentError(
          '`$source` is not one of the supported values: '
          '${enumValues.values.join(', ')}',
        );
      }
      return MapEntry(unknownValue, enumValues.values.first);
    },
  ).key;
}

const _$MovementCategoryEnumMap = {
  MovementCategory.cardio: 'Cardio',
  MovementCategory.strength: 'Strength',
};
