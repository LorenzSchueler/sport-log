import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:sport_log/database/db_interfaces.dart';
import 'package:sport_log/helpers/id_generation.dart';
import 'package:sport_log/database/table.dart';
import 'package:sport_log/helpers/serialization/json_serialization.dart';
import 'package:sport_log/settings.dart';
import 'package:sport_log/widgets/app_icons.dart';

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
        return AppIcons.repeat;
      case MovementDimension.time:
        return AppIcons.timer;
      case MovementDimension.distance:
        return AppIcons.ruler;
      case MovementDimension.energy:
        return AppIcons.gauge;
    }
  }
}

@JsonSerializable()
class Movement extends Entity {
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

  Movement.defaultValue()
      : id = randomId(),
        userId = Settings.userId,
        name = '',
        description = null,
        cardio = true,
        deleted = false,
        dimension = MovementDimension.reps;

  static late Movement
      defaultMovement; // must be initialized in main::initialize

  factory Movement.fromJson(Map<String, dynamic> json) =>
      _$MovementFromJson(json);

  @override
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
        dimension: dimension,
      );

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

class DbMovementSerializer extends DbSerializer<Movement> {
  @override
  Movement fromDbRecord(DbRecord r, {String prefix = ''}) {
    return Movement(
      id: Int64(r[prefix + Columns.id]! as int),
      userId: r[prefix + Columns.userId] == null
          ? null
          : Int64(r[prefix + Columns.userId]! as int),
      name: r[prefix + Columns.name]! as String,
      description: r[prefix + Columns.description] as String?,
      cardio: r[prefix + Columns.cardio]! as int == 1,
      deleted: r[prefix + Columns.deleted]! as int == 1,
      dimension:
          MovementDimension.values[r[prefix + Columns.dimension]! as int],
    );
  }

  @override
  DbRecord toDbRecord(Movement o) {
    return {
      Columns.id: o.id.toInt(),
      Columns.userId: o.userId?.toInt(),
      Columns.name: o.name,
      Columns.description: o.description,
      Columns.cardio: o.cardio ? 1 : 0,
      Columns.deleted: o.deleted ? 1 : 0,
      Columns.dimension: o.dimension.index,
    };
  }
}
