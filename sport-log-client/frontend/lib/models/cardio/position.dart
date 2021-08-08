
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
  @JsonKey(name: "e") double elevation;
  @JsonKey(name: "d") int distance;
  @JsonKey(name: "t") int time;

  factory Position.fromJson(Map<String, dynamic> json) => _$PositionFromJson(json);
  Map<String, dynamic> toJson() => _$PositionToJson(this);
}