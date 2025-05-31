// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mapbox_search_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MapboxForwardResponse _$MapboxForwardResponseFromJson(
  Map<String, dynamic> json,
) => MapboxForwardResponse(
  features: (json['features'] as List<dynamic>)
      .map((e) => Feature.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Feature _$FeatureFromJson(Map<String, dynamic> json) => Feature(
  properties: Properties.fromJson(json['properties'] as Map<String, dynamic>),
  geometry: Geometry.fromJson(json['geometry'] as Map<String, dynamic>),
);

Geometry _$GeometryFromJson(Map<String, dynamic> json) => Geometry(
  coordinates: const CoordinatesConverter().fromJson(
    json['coordinates'] as List,
  ),
);

Coordinates _$CoordinatesFromJson(Map<String, dynamic> json) => Coordinates(
  latitude: (json['latitude'] as num).toDouble(),
  longitude: (json['longitude'] as num).toDouble(),
);

Properties _$PropertiesFromJson(Map<String, dynamic> json) => Properties(
  mapboxId: json['mapbox_id'] as String,
  name: json['name'] as String,
  fullAddress: json['full_address'] as String?,
  coordinates: Coordinates.fromJson(
    json['coordinates'] as Map<String, dynamic>,
  ),
  bbox: _$JsonConverterFromJson<List<dynamic>, BBox>(
    json['bbox'],
    const BBoxConverter().fromJson,
  ),
);

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) => json == null ? null : fromJson(json as Json);
