
import 'package:fixnum/fixnum.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:sport_log/helpers/id_serialization.dart';

part 'movement.g.dart';

enum MovementCategory {
  @JsonValue("Cardio") cardio,
  @JsonValue("Strength") strength,
}

extension MovementCategoryToDisplayName on MovementCategory {
  String toDisplayName() {
    switch (this) {
      case MovementCategory.strength:
        return "strength";
      case MovementCategory.cardio:
        return "cardio";
    }
  }
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

extension MovementUniToDisplayName on MovementUnit {
  String toDisplayName() {
    switch (this) {
      case MovementUnit.reps:
        return "Reps";
      case MovementUnit.cal:
        return "Cals";
      case MovementUnit.meter:
        return "m";
      case MovementUnit.km:
        return "km";
      case MovementUnit.yard:
        return "yd";
      case MovementUnit.foot:
        return "ft";
      case MovementUnit.mile:
        return "mi";
    }
  }
}

@JsonSerializable()
class Movement {
  Movement({
    required this.id,
    required this.userId,
    required this.name,
    required this.description,
    required this.category,
    required this.deleted,
  });

  @IdConverter() Int64 id;
  @OptionalIdConverter() Int64? userId;
  String name;
  String? description;
  MovementCategory category;
  bool deleted;

  factory Movement.fromJson(Map<String, dynamic> json) => _$MovementFromJson(json);
  Map<String, dynamic> toJson() => _$MovementToJson(this);
}