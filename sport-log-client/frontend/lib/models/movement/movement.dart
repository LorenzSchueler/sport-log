
import 'package:json_annotation/json_annotation.dart';

part 'movement.g.dart';

enum MovementCategory {
  @JsonValue("Cardio") cardio,
  @JsonValue("Strength") strength,
}

enum MovementUnit {
  @JsonValue("Reps") reps,
  @JsonValue("Cal") cal,
  @JsonValue("Meter") meter,
  @JsonValue("Km") km,
  @JsonValue("Yard") yard,
  @JsonValue("Foot") foot,
  @JsonValue("Mile") mile,
}

@JsonSerializable()
class Movement {
  Movement({
    required this.id,
    required this.userId,
    required this.name,
    required this.description,
    required this.category,
  });

  int id;
  int? userId;
  String name;
  String? description;
  MovementCategory category;

  factory Movement.fromJson(Map<String, dynamic> json) => _$MovementFromJson(json);
  Map<String, dynamic> toJson() => _$MovementToJson(this);
}