import 'dart:math';

import 'package:collection/collection.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class LatLng {
  const LatLng({required this.lat, required this.lng});

  factory LatLng.fromMap(Map<String?, dynamic> map) {
    final coordinates = map["coordinates"] as List;
    return LatLng(lat: coordinates[1] as double, lng: coordinates[0] as double);
  }

  final double lat;
  final double lng;

  Position _toPosition() => Position(lng, lat);

  Map<String, dynamic> toJsonPoint() =>
      Point(coordinates: _toPosition()).toJson();

  CameraOptions toCameraOptions() => CameraOptions(center: toJsonPoint());

  @override
  String toString() => "lat: $lat, lng: $lng";
}

extension LatLngsExtension on Iterable<LatLng> {
  LatLngBounds? get latLngBounds {
    if (isEmpty) {
      return null;
    }

    final north = map((p) => p.lat).max;
    final south = map((p) => p.lat).min;
    final east = map((p) => p.lng).max;
    final west = map((p) => p.lng).min;

    return LatLngBounds(
      northeast: LatLng(lat: north, lng: east),
      southwest: LatLng(lat: south, lng: west),
    );
  }

  Map<String, dynamic> toGeoJsonLineString() {
    return LineString(
      coordinates: map((latLng) => latLng._toPosition()).toList(),
    ).toJson();
  }
}

class LatLngZoom {
  const LatLngZoom({required this.latLng, required this.zoom});

  final LatLng latLng;
  final double zoom;

  CameraOptions toCameraOptions() =>
      CameraOptions(center: latLng.toJsonPoint(), zoom: zoom);
}

class LatLngBounds {
  LatLngBounds({required this.northeast, required this.southwest});

  LatLng northeast;
  LatLng southwest;

  static LatLngBounds? combinedBounds(
    LatLngBounds? bounds1,
    LatLngBounds? bounds2,
  ) {
    if (bounds1 == null || bounds2 == null) {
      return bounds1 ?? bounds2;
    }

    final north = max(bounds1.northeast.lat, bounds2.northeast.lat);
    final south = min(bounds1.southwest.lat, bounds2.southwest.lat);
    final east = max(bounds1.northeast.lng, bounds2.northeast.lng);
    final west = min(bounds1.southwest.lng, bounds2.southwest.lng);

    return LatLngBounds(
      northeast: LatLng(lat: north, lng: east),
      southwest: LatLng(lat: south, lng: west),
    );
  }

  LatLngBounds padded([double factor = 0.1]) {
    var north = northeast.lat;
    var south = southwest.lat;
    final latDiff = north - south;
    north += latDiff * 0.1;
    south -= latDiff * 0.1;

    var east = northeast.lng;
    var west = southwest.lng;
    final lngDiff = east - west;
    east += lngDiff * factor;
    west -= lngDiff * factor;

    return LatLngBounds(
      northeast: LatLng(lat: north, lng: east),
      southwest: LatLng(lat: south, lng: west),
    );
  }

  CoordinateBounds toCoordinateBounds() => CoordinateBounds(
        southwest: southwest.toJsonPoint(),
        northeast: northeast.toJsonPoint(),
        infiniteBounds: false,
      );

  Map<String, dynamic> toGeoJsonLineString() => [
        northeast,
        LatLng(lat: northeast.lat, lng: southwest.lng),
        southwest,
        LatLng(lat: southwest.lat, lng: northeast.lng),
        northeast,
      ].toGeoJsonLineString();

  LatLng get center {
    final north = northeast.lat;
    final south = southwest.lat;
    final east = northeast.lng;
    final west = southwest.lng;

    return LatLng(lat: (north + south) / 2, lng: (east + west) / 2);
  }
}
