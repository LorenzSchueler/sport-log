import 'package:fixnum/fixnum.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:sport_log/database/defs.dart';
import 'package:sport_log/helpers/id_generation.dart';
import 'package:sport_log/database/keys.dart';
import 'package:sport_log/helpers/serialization/json_serialization.dart';

part 'movement.g.dart';

enum MovementUnit {
  @JsonValue("Reps")
  reps,
  @JsonValue("Cal")
  cals,
  @JsonValue("Meter")
  m,
  @JsonValue("Km")
  km,
  @JsonValue("Yard")
  yards,
  @JsonValue("Foot")
  feet,
  @JsonValue("Mile")
  miles,
  @JsonValue("Msec")
  msecs,
}

extension MovementUnitStrings on MovementUnit {
  String toDisplayName() {
    switch (this) {
      case MovementUnit.reps:
        return "reps";
      case MovementUnit.cals:
        return "cals";
      case MovementUnit.m:
        return "m";
      case MovementUnit.km:
        return "km";
      case MovementUnit.yards:
        return "yd";
      case MovementUnit.feet:
        return "ft";
      case MovementUnit.miles:
        return "mi";
      case MovementUnit.msecs:
        return "ms";
    }
  }

  String toDimensionName() {
    switch (this) {
      case MovementUnit.reps:
        return "Reps";
      case MovementUnit.cals:
        return "Cals";
      case MovementUnit.m:
      case MovementUnit.km:
      case MovementUnit.yards:
      case MovementUnit.feet:
      case MovementUnit.miles:
        return "Distance";
      case MovementUnit.msecs:
        return "Time";
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
    required this.cardio,
    required this.deleted,
    required this.unit,
  });

  @override
  @IdConverter()
  Int64 id;
  @OptionalIdConverter()
  Int64? userId;
  String name;
  String? description;
  bool cardio;
  @override
  bool deleted;
  @JsonKey(name: 'movement_unit')
  MovementUnit unit;

  Movement.defaultValue(this.userId)
      : id = randomId(),
        name = '',
        description = null,
        cardio = true,
        deleted = false,
        unit = MovementUnit.reps;

  factory Movement.fromJson(Map<String, dynamic> json) =>
      _$MovementFromJson(json);

  Map<String, dynamic> toJson() => _$MovementToJson(this);

  @override
  bool isValid() {
    return validate(name.isNotEmpty, 'Movement: name is empty') &&
        validate(deleted == false, 'Movement: deleted == true');
  }

  Movement copy() => Movement(
      id: id,
      userId: userId,
      name: name,
      description: description,
      cardio: cardio,
      deleted: deleted,
      unit: unit);

  @override
  bool operator ==(other) =>
      other is Movement &&
      other.id == id &&
      other.userId == userId &&
      other.name == name &&
      other.description == description &&
      other.cardio == cardio &&
      other.deleted == deleted &&
      other.unit == unit;

  @override
  int get hashCode =>
      Object.hash(id, userId, name, description, cardio, deleted, unit);
}

class DbMovementSerializer implements DbSerializer<Movement> {
  @override
  Movement fromDbRecord(DbRecord r, {String prefix = ''}) {
    return Movement(
      id: Int64(r[prefix + Keys.id]! as int),
      userId: r[prefix + Keys.userId] == null
          ? null
          : Int64(r[prefix + Keys.userId]! as int),
      name: r[prefix + Keys.name]! as String,
      description: r[prefix + Keys.description] as String?,
      cardio: r[prefix + Keys.cardio]! as int == 1,
      deleted: r[prefix + Keys.deleted]! as int == 1,
      unit: MovementUnit.values[r[prefix + Keys.unit]! as int],
    );
  }

  @override
  DbRecord toDbRecord(Movement o) {
    return {
      Keys.id: o.id.toInt(),
      Keys.userId: o.userId?.toInt(),
      Keys.name: o.name,
      Keys.description: o.description,
      Keys.cardio: o.cardio ? 1 : 0,
      Keys.deleted: o.deleted ? 1 : 0,
      Keys.unit: o.unit.index,
    };
  }
}
