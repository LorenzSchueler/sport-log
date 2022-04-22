import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:sport_log/helpers/extensions/iterable_extension.dart';

extension LatLngsExtension on List<LatLng> {
  LatLngBounds? get latLngBounds {
    if (isEmpty) {
      return null;
    }
    double north = map((p) => p.latitude).max;
    double south = map((p) => p.latitude).min;
    double latDiff = north - south;
    north += latDiff * 0.1;
    south -= latDiff * 0.1;

    double east = map((p) => p.longitude).max;
    double west = map((p) => p.longitude).min;
    double longDiff = east - west;
    east += longDiff * 0.1;
    west -= longDiff * 0.1;

    return LatLngBounds(
      northeast: LatLng(north, east),
      southwest: LatLng(south, west),
    );
  }
}
