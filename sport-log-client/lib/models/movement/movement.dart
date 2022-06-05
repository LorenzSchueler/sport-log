import 'package:fixnum/fixnum.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:sport_log/database/db_interfaces.dart';
import 'package:sport_log/database/table.dart';
import 'package:sport_log/helpers/id_generation.dart';
import 'package:sport_log/helpers/serialization/json_serialization.dart';
import 'package:sport_log/models/clone_extensions.dart';
import 'package:sport_log/models/entity_interfaces.dart';
import 'package:sport_log/settings.dart';

part 'movement.g.dart';

enum MovementDimension {
  @JsonValue('Reps')
  reps,
  @JsonValue('Time')
  time,
  @JsonValue('Distance')
  distance,
  @JsonValue('Energy')
  energy;

  @override
  String toString() {
    switch (this) {
      case MovementDimension.reps:
        return 'Reps';
      case MovementDimension.energy:
        return 'Calories';
      case MovementDimension.distance:
        return 'Distance';
      case MovementDimension.time:
        return 'Time';
    }
  }
}

@JsonSerializable()
class Movement extends AtomicEntity {
  Movement({
    required this.id,
    required this.userId,
    required this.name,
    required this.description,
    required this.cardio,
    required this.deleted,
    required this.dimension,
  });

  factory Movement.fromJson(Map<String, dynamic> json) =>
      _$MovementFromJson(json);

  Movement.defaultValue()
      : id = randomId(),
        userId = Settings.userId,
        name = '',
        description = null,
        cardio = true,
        deleted = false,
        dimension = MovementDimension.reps;

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

  static Movement?
      _defaultMovement; // default movement that already exists in db
  static set defaultMovement(Movement? movement) => _defaultMovement = movement;
  static Movement? get defaultMovement => _defaultMovement?.clone();

  @override
  Map<String, dynamic> toJson() => _$MovementToJson(this);

  @override
  Movement clone() => Movement(
        id: id.clone(),
        userId: userId?.clone(),
        name: name,
        description: description,
        cardio: cardio,
        deleted: deleted,
        dimension: dimension,
      );

  @override
  bool isValidBeforeSanitazion() {
    return validate(!deleted, 'Movement: deleted == true') &&
        validate(
          name.length >= 2 && name.length <= 80,
          'Movement: name.length is < 2 or > 80',
        );
  }

  @override
  bool isValid() {
    return isValidBeforeSanitazion() &&
        validate(
          description == null || description!.isNotEmpty,
          'Movement: desciption is empty but not null',
        );
  }

  @override
  void sanitize() {
    if (description != null && description!.isEmpty) {
      description = null;
    }
  }

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
