import 'package:json_annotation/json_annotation.dart';

part 'mapbox_search_models.g.dart';

@JsonSerializable(createToJson: false)
class MapboxForwardResponse {
  MapboxForwardResponse({required this.features});

  factory MapboxForwardResponse.fromJson(Map<String, dynamic> json) =>
      _$MapboxForwardResponseFromJson(json);

  final List<Feature> features;
}

@JsonSerializable(createToJson: false)
class Feature {
  Feature({required this.properties, required this.geometry});

  factory Feature.fromJson(Map<String, dynamic> json) =>
      _$FeatureFromJson(json);

  final Geometry geometry;
  final Properties properties;
}

@JsonSerializable(createToJson: false)
class Geometry {
  Geometry({required this.coordinates});

  factory Geometry.fromJson(Map<String, dynamic> json) =>
      _$GeometryFromJson(json);

  @CoordinatesConverter()
  final Coordinates coordinates;
}

@JsonSerializable(createToJson: false)
class Coordinates {
  Coordinates({required this.latitude, required this.longitude});

  factory Coordinates.fromJson(Map<String, dynamic> json) =>
      _$CoordinatesFromJson(json);

  final double latitude;
  final double longitude;
}

class CoordinatesConverter
    implements JsonConverter<Coordinates, List<dynamic>> {
  const CoordinatesConverter();

  @override
  Coordinates fromJson(List<dynamic> json) {
    if (json.length == 2) {
      return Coordinates(
        longitude: (json[0] as num?)?.toDouble() ?? 0.0,
        latitude: (json[1] as num?)?.toDouble() ?? 0.0,
      );
    }
    return Coordinates(longitude: 0, latitude: 0);
  }

  @override
  List<dynamic> toJson(Coordinates object) {
    return [object.longitude, object.latitude];
  }
}

class BBox {
  BBox({
    required this.minLatitude,
    required this.minLongitude,
    required this.maxLatitude,
    required this.maxLongitude,
  });

  final double minLatitude;
  final double minLongitude;
  final double maxLatitude;
  final double maxLongitude;
}

class BBoxConverter implements JsonConverter<BBox, List<dynamic>> {
  const BBoxConverter();

  @override
  BBox fromJson(List<dynamic> json) {
    if (json.length == 4) {
      return BBox(
        minLongitude: (json[0] as num?)?.toDouble() ?? 0.0,
        minLatitude: (json[1] as num?)?.toDouble() ?? 0.0,
        maxLongitude: (json[2] as num?)?.toDouble() ?? 0.0,
        maxLatitude: (json[3] as num?)?.toDouble() ?? 0.0,
      );
    }
    return BBox(
      minLongitude: 0,
      minLatitude: 0,
      maxLongitude: 0,
      maxLatitude: 0,
    );
  }

  @override
  List<dynamic> toJson(BBox object) {
    return [
      object.minLongitude,
      object.minLatitude,
      object.maxLongitude,
      object.maxLatitude,
    ];
  }
}

@JsonSerializable(createToJson: false)
class Properties {
  Properties({
    required this.mapboxId,
    required this.name,
    this.fullAddress,
    required this.coordinates,
    this.bbox,
  });

  factory Properties.fromJson(Map<String, dynamic> json) =>
      _$PropertiesFromJson(json);

  @JsonKey(name: 'mapbox_id')
  final String mapboxId;
  final String name;
  @JsonKey(name: 'full_address')
  final String? fullAddress;
  final Coordinates coordinates;
  @BBoxConverter()
  final BBox? bbox;
}
