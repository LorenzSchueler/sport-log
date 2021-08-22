
import 'dart:typed_data';

import 'package:json_annotation/json_annotation.dart';

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

  @JsonKey(name: "lo") double longitude;
  @JsonKey(name: "la") double latitude;
  @JsonKey(name: "e") int elevation;
  @JsonKey(name: "d") int distance;
  @JsonKey(name: "t") int time;

  factory Position.fromJson(Map<String, dynamic> json) => _$PositionFromJson(json);
  Map<String, dynamic> toJson() => _$PositionToJson(this);

  static const int byteSize = 40;

  Uint8List asBytesList() {
    final bytes = ByteData(byteSize)
      ..setFloat64(0, longitude)
      ..setFloat64(8, latitude)
      ..setInt64(16, elevation)
      ..setInt64(24, distance)
      ..setInt64(32, time);
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
      time: bytes.getInt64(32),
    );
  }

  @override
  bool operator ==(Object other) {
    if (other is! Position) {
      return false;
    }
    return longitude == other.longitude
        && latitude == other.latitude
        && elevation == other.elevation
        && distance == other.distance
        && time == other.time;
  }
}