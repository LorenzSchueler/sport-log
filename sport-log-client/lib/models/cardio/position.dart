import 'dart:typed_data';

import 'package:json_annotation/json_annotation.dart';
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
    final bytes =
        ByteData(byteSize)
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

  double distanceTo(Position other) => latLng.distanceTo(other.latLng);

  (double, int?) minDistanceTo(List<Position> track) =>
      latLng.minDistanceTo(track.latLngs);
}

extension TrackExtension on List<Position> {
  List<LatLng> get latLngs => map((pos) => pos.latLng).toList();

  LatLngBounds? get latLngBounds => latLngs.latLngBounds;

  bool similarTo(List<Position> other) => latLngs.similarTo(other.latLngs);
}
