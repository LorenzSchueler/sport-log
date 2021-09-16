// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'movement.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Movement _$MovementFromJson(Map<String, dynamic> json) {
  return Movement(
    id: const IdConverter().fromJson(json['id'] as String),
    userId: const OptionalIdConverter().fromJson(json['user_id'] as String?),
    name: json['name'] as String,
    description: json['description'] as String?,
    categories: (json['categories'] as List<dynamic>)
        .map((e) => _$enumDecode(_$MovementCategoryEnumMap, e))
        .toList(),
    deleted: json['deleted'] as bool,
  );
}

Map<String, dynamic> _$MovementToJson(Movement instance) => <String, dynamic>{
      'id': const IdConverter().toJson(instance.id),
      'user_id': const OptionalIdConverter().toJson(instance.userId),
      'name': instance.name,
      'description': instance.description,
      'categories':
          instance.categories.map((e) => _$MovementCategoryEnumMap[e]).toList(),
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
