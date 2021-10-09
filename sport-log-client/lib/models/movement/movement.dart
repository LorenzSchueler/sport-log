import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:sport_log/database/defs.dart';
import 'package:sport_log/helpers/id_generation.dart';
import 'package:sport_log/database/keys.dart';
import 'package:sport_log/helpers/serialization/json_serialization.dart';
import 'package:sport_log/widgets/custom_icons.dart';

part 'movement.g.dart';

enum MovementDimension {
  @JsonValue('Reps')
  reps,
  @JsonValue('Time')
  time,
  @JsonValue('Distance')
  distance,
  @JsonValue('Energy')
  energy,
}

extension MovementDimensionStrings on MovementDimension {
  String get displayName {
    switch (this) {
      case MovementDimension.reps:
        return 'Reps';
      case MovementDimension.energy:
        return 'Energy';
      case MovementDimension.distance:
        return 'Distance';
      case MovementDimension.time:
        return 'Time';
    }
  }

  IconData get iconData {
    switch (this) {
      case MovementDimension.reps:
        return CustomIcons.cw_1;
      case MovementDimension.time:
        return CustomIcons.stopwatch;
      case MovementDimension.distance:
        return CustomIcons.ruler;
      case MovementDimension.energy:
        return CustomIcons.fire;
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
    required this.dimension,
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
  @JsonKey(name: 'movement_dimension')
  MovementDimension dimension;

  Movement.defaultValue(this.userId)
      : id = randomId(),
        name = '',
        description = null,
        cardio = true,
        deleted = false,
        dimension = MovementDimension.reps;

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
      dimension: dimension);

  @override
  bool operator ==(other) =>
      other is Movement &&
      other.id == id &&
      other.userId == userId &&
      other.name == name &&
      other.description == description &&
      other.cardio == cardio &&
      other.deleted == deleted &&
      other.dimension == dimension;

  @override
  int get hashCode =>
      Object.hash(id, userId, name, description, cardio, deleted, dimension);
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
      dimension: MovementDimension.values[r[prefix + Keys.dimension]! as int],
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
      Keys.dimension: o.dimension.index,
    };
  }
}
