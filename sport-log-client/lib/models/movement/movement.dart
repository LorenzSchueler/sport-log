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
  reps("Reps"),
  @JsonValue('Time')
  time("Time"),
  @JsonValue('Distance')
  distance("Distance"),
  @JsonValue('Energy')
  energy("Calories");

  const MovementDimension(this.name);

  final String name;
}

@JsonSerializable(constructor: "_")
class Movement extends AtomicEntity {
  Movement({
    required this.id,
    required this.isDefaultMovement,
    required this.name,
    required this.description,
    required this.cardio,
    required this.deleted,
    required this.dimension,
  });

  Movement._({
    required this.id,
    required Int64? userId,
    required this.name,
    required this.description,
    required this.cardio,
    required this.deleted,
    required this.dimension,
  }) : isDefaultMovement = userId == null;

  factory Movement.fromJson(Map<String, dynamic> json) =>
      _$MovementFromJson(json);

  Movement.defaultValue()
    : id = randomId(),
      isDefaultMovement = false,
      name = '',
      description = null,
      cardio = true,
      deleted = false,
      dimension = MovementDimension.reps;

  @override
  @IdConverter()
  Int64 id;
  @Deprecated("Use isDefaultMovement instead")
  @JsonKey(includeToJson: true)
  @OptionalIdConverter()
  Int64? get userId => isDefaultMovement ? null : Settings.instance.userId!;
  @JsonKey(includeFromJson: false)
  bool isDefaultMovement;
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
    isDefaultMovement: isDefaultMovement,
    name: name,
    description: description,
    cardio: cardio,
    deleted: deleted,
    dimension: dimension,
  );

  @override
  bool isValidBeforeSanitation() {
    return validate(!deleted, 'Movement: deleted == true') &&
        validate(
          name.length >= 2 && name.length <= 80,
          'Movement: name.length is < 2 or > 80',
        );
  }

  @override
  bool isValid() {
    return isValidBeforeSanitation() &&
        validate(
          description == null || description!.isNotEmpty,
          'Movement: description is empty but not null',
        );
  }

  @override
  void sanitize() {
    if (description != null && description!.isEmpty) {
      description = null;
    }
  }

  @override
  bool operator ==(Object other) =>
      other is Movement &&
      other.id == id &&
      other.isDefaultMovement == isDefaultMovement &&
      other.name == name &&
      other.description == description &&
      other.cardio == cardio &&
      other.deleted == deleted &&
      other.dimension == dimension;

  @override
  int get hashCode => Object.hash(
    id,
    isDefaultMovement,
    name,
    description,
    cardio,
    deleted,
    dimension,
  );
}

class DbMovementSerializer extends DbSerializer<Movement> {
  @override
  Movement fromDbRecord(DbRecord r, {String prefix = ''}) {
    return Movement(
      id: Int64(r[prefix + Columns.id]! as int),
      isDefaultMovement: r[prefix + Columns.isDefaultMovement]! as int == 1,
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
      Columns.isDefaultMovement: o.isDefaultMovement ? 1 : 0,
      Columns.name: o.name,
      Columns.description: o.description,
      Columns.cardio: o.cardio ? 1 : 0,
      Columns.deleted: o.deleted ? 1 : 0,
      Columns.dimension: o.dimension.index,
    };
  }
}
