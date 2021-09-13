import 'package:fixnum/fixnum.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:sport_log/database/defs.dart';
import 'package:sport_log/helpers/id_generation.dart';
import 'package:sport_log/helpers/serialization/json_serialization.dart';

part 'movement.g.dart';

enum MovementCategory {
  @JsonValue("Cardio")
  cardio,
  @JsonValue("Strength")
  strength,
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
  @JsonValue("Reps")
  reps,
  @JsonValue("Cal")
  cal,
  @JsonValue("Meter")
  meter,
  @JsonValue("Km")
  km,
  @JsonValue("Yard")
  yard,
  @JsonValue("Foot")
  foot,
  @JsonValue("Mile")
  mile,
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
class Movement implements DbObject {
  Movement({
    required this.id,
    required this.userId,
    required this.name,
    required this.description,
    required this.category,
    required this.deleted,
  });

  @override
  @IdConverter()
  Int64 id;
  @OptionalIdConverter()
  Int64? userId;
  String name;
  String? description;
  MovementCategory category;
  @override
  bool deleted;

  Movement.defaultValue(this.userId)
      : id = randomId(),
        name = '',
        description = null,
        category = MovementCategory.strength,
        deleted = false;

  factory Movement.fromJson(Map<String, dynamic> json) =>
      _$MovementFromJson(json);

  Map<String, dynamic> toJson() => _$MovementToJson(this);

  @override
  bool isValid() {
    return validate(userId != null, 'Movement: userId == null') &&
        validate(name.isNotEmpty, 'Movement: name is empty') &&
        validate(deleted == false, 'Movement: deleted == true');
  }
}

class DbMovementSerializer implements DbSerializer<Movement> {
  @override
  Movement fromDbRecord(DbRecord r) {
    return Movement(
      id: Int64(r[Keys.id]! as int),
      userId: r[Keys.userId] == null ? null : Int64(r[Keys.userId]! as int),
      name: r[Keys.name]! as String,
      description: r[Keys.description] as String?,
      category: MovementCategory.values[r[Keys.category]! as int],
      deleted: r[Keys.deleted]! as int == 1,
    );
  }

  @override
  DbRecord toDbRecord(Movement o) {
    return {
      Keys.id: o.id.toInt(),
      Keys.userId: o.userId?.toInt(),
      Keys.name: o.name,
      Keys.description: o.description,
      Keys.category: o.category.index,
      Keys.deleted: o.deleted ? 1 : 0,
    };
  }
}
