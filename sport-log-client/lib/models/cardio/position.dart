import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:sport_log/helpers/extensions/iterable_extension.dart';
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

  factory Position.fromJson(Map<String, dynamic> json) =>
      _$PositionFromJson(json);

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

  @override
  bool operator ==(Object other) {
    if (other is! Position) {
      return false;
    }
    return longitude == other.longitude &&
        latitude == other.latitude &&
        elevation == other.elevation &&
        distance == other.distance &&
        time == other.time;
  }

  @override
  int get hashCode =>
      hashValues(longitude, latitude, elevation, distance, time);

  LatLng get latLng => LatLng(latitude, longitude);

  double distanceTo(double otherLatitude, double otherLongitude) {
    return const latlong.Distance().as(
      latlong.LengthUnit.Meter,
      latlong.LatLng(latitude, longitude),
      latlong.LatLng(otherLatitude, otherLongitude),
    );
  }

  double addDistanceTo(double otherLatitude, double otherLongitude) {
    return distance + distanceTo(otherLatitude, otherLongitude);
  }
}

extension TrackLatLngBounds on List<Position> {
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

extension TrackToLatLngs on List<Position> {
  List<LatLng> get latLngs {
    return map((pos) => pos.latLng).toList();
  }
}

extension LatLngBoundsCombine on LatLngBounds {
  static LatLngBounds? combinedBounds(
    List<Position>? track1,
    List<Position>? track2,
  ) {
    final bounds1 = track1?.latLngBounds;
    final bounds2 = track2?.latLngBounds;
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
}
