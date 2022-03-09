import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
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
  int elevation;
  @JsonKey(name: "d")
  int distance;
  @JsonKey(name: "t")
  @DurationConverter()
  Duration time;

  factory Position.fromJson(Map<String, dynamic> json) =>
      _$PositionFromJson(json);

  Map<String, dynamic> toJson() => _$PositionToJson(this);

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
      ..setInt64(16, elevation)
      ..setInt64(24, distance)
      ..setInt64(32, time.inSeconds);
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
      elevation: bytes.getInt64(16),
      distance: bytes.getInt64(24),
      time: Duration(seconds: bytes.getInt64(32)),
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
}

extension TrackLatLngBounds on List<Position> {
  LatLngBounds get latLngBounds {
    double north = map((p) => p.latitude).max;
    double south = map((p) => p.latitude).min;
    double latDiff = north - south;
    north += 0.1 * latDiff;
    south -= 0.1 * latDiff;

    double east = map((p) => p.longitude).max;
    double west = map((p) => p.longitude).min;
    double longDiff = east - west;
    east += 0.1 * longDiff;
    west -= 0.1 * longDiff;

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
