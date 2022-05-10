import 'dart:math';

import 'package:collection/collection.dart';
import 'package:mapbox_gl/mapbox_gl.dart';

extension LatLngsExtension on List<LatLng> {
  LatLngBounds? get latLngBounds {
    if (isEmpty) {
      return null;
    }

    double north = map((p) => p.latitude).max;
    double south = map((p) => p.latitude).min;
    double east = map((p) => p.longitude).max;
    double west = map((p) => p.longitude).min;

    return LatLngBounds(
      northeast: LatLng(north, east),
      southwest: LatLng(south, west),
    );
  }
}

extension LatLngBoundsCombine on LatLngBounds {
  static LatLngBounds? combinedBounds(
    LatLngBounds? bounds1,
    LatLngBounds? bounds2,
  ) {
    if (bounds1 == null || bounds2 == null) {
      return bounds1 ?? bounds2;
    }

    final north = max(bounds1.northeast.latitude, bounds2.northeast.latitude);
    final south = min(bounds1.southwest.latitude, bounds2.southwest.latitude);
    final east = max(bounds1.northeast.longitude, bounds2.northeast.longitude);
    final west = min(bounds1.southwest.longitude, bounds2.southwest.longitude);

    return LatLngBounds(
      northeast: LatLng(north, east),
      southwest: LatLng(south, west),
    );
  }

  LatLngBounds padded() {
    double north = northeast.latitude;
    double south = southwest.latitude;
    double latDiff = north - south;
    north += latDiff * 0.1;
    south -= latDiff * 0.1;

    double east = northeast.longitude;
    double west = southwest.longitude;
    double longDiff = east - west;
    east += longDiff * 0.1;
    west -= longDiff * 0.1;

    return LatLngBounds(
      northeast: LatLng(north, east),
      southwest: LatLng(south, west),
    );
  }
}
