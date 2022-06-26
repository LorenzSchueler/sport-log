import 'dart:typed_data';

import 'package:json_annotation/json_annotation.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:sport_log/helpers/extensions/lat_lng_extension.dart';
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
      Object.hash(longitude, latitude, elevation, distance, time);

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

extension TrackExtension on List<Position> {
  LatLngBounds? get latLngBounds => map((p) => p.latLng).toList().latLngBounds;

  List<LatLng> get latLngs => map((pos) => pos.latLng).toList();
}
