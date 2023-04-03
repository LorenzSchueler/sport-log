import 'dart:math';
import 'dart:typed_data';

import 'package:json_annotation/json_annotation.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:sport_log/helpers/lat_lng.dart';
import 'package:sport_log/helpers/serialization/json_serialization.dart';
import 'package:sport_log/models/clone_extensions.dart';

part 'position.g.dart';

@JsonSerializable()
class Position {
  Position({
    required this.longitude,
    required this.latitude,
    required this.elevation,
    required this.distance,
    required this.time,
  });

  factory Position.fromJson(Map<String, dynamic> json) =>
      _$PositionFromJson(json);

  factory Position.fromBytesList(Uint8List list) {
    assert(list.length == byteSize);
    final bytes = list.buffer.asByteData();
    return Position(
      longitude: bytes.getFloat64(0),
      latitude: bytes.getFloat64(8),
      elevation: bytes.getFloat64(16),
      distance: bytes.getFloat64(24),
      time: Duration(milliseconds: bytes.getInt64(32)),
    );
  }

  @JsonKey(name: "lo")
  double longitude;
  @JsonKey(name: "la")
  double latitude;
  @JsonKey(name: "e")
  double elevation;
  @JsonKey(name: "d")
  double distance;
  @JsonKey(name: "t")
  @DurationConverter()
  Duration time;

  Map<String, dynamic> toJson() => _$PositionToJson(this);

  @override
  String toString() => toJson().toString();

  Position clone() => Position(
        longitude: longitude,
        latitude: latitude,
        elevation: elevation,
        distance: distance,
        time: time.clone(),
      );

  static const int byteSize = 40;

  Uint8List asBytesList() {
    final bytes = ByteData(byteSize)
      ..setFloat64(0, longitude)
      ..setFloat64(8, latitude)
      ..setFloat64(16, elevation)
      ..setFloat64(24, distance)
      ..setInt64(32, time.inMilliseconds);
    final list = bytes.buffer.asUint8List();
    assert(list.length == byteSize);
    return list;
  }

  @override
  bool operator ==(Object other) {
    return other is Position &&
        longitude == other.longitude &&
        latitude == other.latitude &&
        elevation == other.elevation &&
        distance == other.distance &&
        time == other.time;
  }

  @override
  int get hashCode =>
      Object.hash(longitude, latitude, elevation, distance, time);

  LatLng get latLng => LatLng(lat: latitude, lng: longitude);

  double distanceTo(LatLng other) =>
      const latlong.Distance(roundResult: false).distance(
        latlong.LatLng(latitude, longitude),
        latlong.LatLng(other.lat, other.lng),
      ); // in m

  // optimized haversine for small angles between points
  double _fastDistanceTo(Position other) {
    double rad(double degree) => degree / 180 * pi;

    const R = 6371000; // radius of the earth in m
    final x = (rad(latLng.lng) - rad(other.latLng.lng)) *
        cos(0.5 * (rad(latLng.lat) + rad(other.latLng.lat)));
    final y = rad(latLng.lat) - rad(other.latLng.lat);
    return R * sqrt(x * x + y * y);
  } // in m

  double minDistanceTo(List<Position> track) {
    var minDistance = double.infinity;
    for (final point in track) {
      final distance = _fastDistanceTo(point);
      if (distance < minDistance) {
        minDistance = distance;
      }
    }
    return minDistance;
  }

  double addDistanceTo(LatLng latLng) => distance + distanceTo(latLng);
}

extension TrackExtension on List<Position> {
  LatLngBounds? get latLngBounds => map((p) => p.latLng).toList().latLngBounds;

  List<LatLng> get latLngs => map((pos) => pos.latLng).toList();

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
    List<Position> track1,
    List<Position> track2,
  ) {
    bool check(List<Position> track1, List<Position> track2) {
      var index = 0;
      outer:
      for (final point in track1) {
        for (var i = index; i < track2.length; i++) {
          if (point._fastDistanceTo(track2[i]) < maxDistance) {
            index = i;
            break outer;
          }
        }
        return false;
      }
      return true;
    }

    return check(track1, track2) && check(track2, track1);
  }

  bool similarTo(List<Position> other) {
    const maxDistance = 50;
    return isNotEmpty &&
        other.isNotEmpty &&
        first._fastDistanceTo(other.first) < maxDistance && // start
        last._fastDistanceTo(other.last) < maxDistance && // end
        _checkMaxDistance(maxDistance, this, other);
  }
}
