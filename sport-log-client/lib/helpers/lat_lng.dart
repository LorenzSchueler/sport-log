import 'dart:math';

import 'package:collection/collection.dart';
import 'package:latlong2/latlong.dart' as lat_long;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class LatLng {
  const LatLng({required this.lat, required this.lng});

  LatLng.fromPoint(Point point)
    : lat = point.coordinates.lat as double,
      lng = point.coordinates.lng as double;

  final double lat;
  final double lng;

  Position _toPosition() => Position(lng, lat);

  Point toPoint() => Point(coordinates: _toPosition());

  CameraOptions toCameraOptionsCenter() => CameraOptions(center: toPoint());

  @override
  bool operator ==(Object other) =>
      other is LatLng && lat == other.lat && lng == other.lng;

  @override
  int get hashCode => Object.hash(lat, lng);

  @override
  String toString() {
    String toDegreeMinDec(double coord, String pos, String neg) {
      final isPos = coord >= 0;
      final absCoord = coord.abs();
      final degree = absCoord.truncate();
      final minutes = ((absCoord - degree) * 60).toStringAsFixed(3);
      return "$degree°$minutes'${isPos ? pos : neg}";
    }

    return "${toDegreeMinDec(lat, "N", "S")} ${toDegreeMinDec(lng, "O", "W")}";
  }

  double distanceTo(LatLng other) => const lat_long.Distance(roundResult: false)
      .distance(
        lat_long.LatLng(lat, lng),
        lat_long.LatLng(other.lat, other.lng),
      ); // in m

  // optimized haversine for small angles between points
  double _fastDistanceTo(LatLng other) {
    double rad(double degree) => degree / 180 * pi;

    const R = 6371000; // radius of the earth in m
    final x =
        (rad(lng) - rad(other.lng)) * cos(0.5 * (rad(lat) + rad(other.lat)));
    final y = rad(lat) - rad(other.lat);
    return R * sqrt(x * x + y * y);
  } // in m

  /// Return the minimum distance in meter and the index of the closest point.
  (double, int?) minDistanceTo(List<LatLng> track) {
    var minDistance = double.infinity;
    int? index;
    for (var i = 0; i < track.length; i++) {
      final distance = _fastDistanceTo(track[i]);
      if (distance < minDistance) {
        minDistance = distance;
        index = i;
      }
    }
    return (minDistance, index);
  }
}

extension LatLngListExtension on List<LatLng> {
  /// Check that every point of each track is within `maxDistance` of any point of the other track
  /// that comes after (or is the same as) the matching point of the previous point of this track.
  /// That is, if point 3 of track 2 is the first point that is within `maxDistance` of point 1 of track 1,
  /// then we only check the points starting from point 3 in track 2 to find a point that is within `maxDistance` to point 2 of track 1.
  ///
  /// Because we do not care about the average or minimal distance and only want to make sure
  /// that every point of one track is within `maxDistance` of any point of the other track,
  /// we can avoid the quadratic complexity of
  /// [Dynamic Time Warping](https://en.wikipedia.org/wiki/Dynamic_time_warping) or
  /// [Fréchet distance](https://en.wikipedia.org/wiki/Fr%C3%A9chet_distance) and implement it in linear time.
  /// Although we have a nested loop over the points of both tracks, the time is linear
  /// because we skip all already consumed elements of the inner track (except the last one)
  /// and stop once we find a point within `maxDistance`.
  /// The next time around we start at this position.
  /// This way every track in only traversed once.
  static bool _checkMaxDistance(
    int maxDistance,
    List<LatLng> track1,
    List<LatLng> track2,
  ) {
    bool check(List<LatLng> track1, List<LatLng> track2) {
      var index = 0;
      outer:
      for (final point in track1) {
        for (var i = index; i < track2.length; i++) {
          if (point._fastDistanceTo(track2[i]) < maxDistance) {
            index = i;
            continue outer;
          }
        }
        return false;
      }
      return true;
    }

    return check(track1, track2) && check(track2, track1);
  }

  bool similarTo(List<LatLng> other) {
    const maxDistance = 50;
    return isNotEmpty &&
        other.isNotEmpty &&
        first._fastDistanceTo(other.first) < maxDistance && // start
        last._fastDistanceTo(other.last) < maxDistance && // end
        _checkMaxDistance(maxDistance, this, other);
  }
}

extension LatLngIterExtension on Iterable<LatLng> {
  LatLngBounds? get latLngBounds {
    if (isEmpty) {
      return null;
    }

    return LatLngBounds(
      north: map((p) => p.lat).max,
      south: map((p) => p.lat).min,
      east: map((p) => p.lng).max,
      west: map((p) => p.lng).min,
    );
  }

  LineString toLineString() =>
      LineString(coordinates: map((latLng) => latLng._toPosition()).toList());
}

class LatLngZoom {
  const LatLngZoom({required this.latLng, required this.zoom});

  final LatLng latLng;
  final double zoom;

  CameraOptions toCameraOptions() =>
      CameraOptions(center: latLng.toPoint(), zoom: zoom);
}

class LatLngBounds {
  const LatLngBounds({
    required this.north,
    required this.south,
    required this.east,
    required this.west,
  });

  /// List of [north, east, south, west] like the one produced by `LatLngBounds.toList()`.
  LatLngBounds.fromList(List<double> l)
    : north = l[0],
      east = l[1],
      south = l[2],
      west = l[3];

  final double north;
  final double south;
  final double east;
  final double west;

  static LatLngBounds? combinedBounds(
    LatLngBounds? bounds1,
    LatLngBounds? bounds2,
  ) {
    if (bounds1 == null || bounds2 == null) {
      return bounds1 ?? bounds2;
    }

    return LatLngBounds(
      north: max(bounds1.north, bounds2.north),
      south: min(bounds1.south, bounds2.south),
      east: max(bounds1.east, bounds2.east),
      west: min(bounds1.west, bounds2.west),
    );
  }

  Polygon toPolygon() => Polygon(
    coordinates: [
      [
        Position(east, north),
        Position(west, north),
        Position(west, south),
        Position(east, south),
      ],
    ],
  );

  /// List of [north, east, south, west].
  List<double> toList() => [north, east, south, west];

  LineString toLineString() => LineString(
    coordinates: [
      Position(east, north),
      Position(west, north),
      Position(west, south),
      Position(east, south),
      Position(east, north),
    ],
  );

  LatLng get center => LatLng(lat: (north + south) / 2, lng: (east + west) / 2);
}
