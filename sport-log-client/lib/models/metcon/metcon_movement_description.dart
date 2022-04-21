import 'package:json_annotation/json_annotation.dart';
import 'package:sport_log/database/db_interfaces.dart';
import 'package:sport_log/helpers/extensions/date_time_extension.dart';
import 'package:sport_log/models/entity_interfaces.dart';
import 'package:sport_log/models/metcon/all.dart';
import 'package:sport_log/models/movement/movement.dart';

part 'metcon_movement_description.g.dart';

@JsonSerializable()
class MetconMovementDescription extends CompoundEntity {
  MetconMovementDescription({
    required this.metconMovement,
    required this.movement,
  });

  MetconMovement metconMovement;
  Movement movement;

  factory MetconMovementDescription.fromJson(Map<String, dynamic> json) =>
      _$MetconMovementDescriptionFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$MetconMovementDescriptionToJson(this);

  @override
  MetconMovementDescription clone() => MetconMovementDescription(
        metconMovement: metconMovement.clone(),
        movement: movement.clone(),
      );

  @override
  bool isValidBeforeSanitazion() {
    return validate(
          metconMovement.isValidBeforeSanitazion(),
          'MetconMovementDescription: metcon movement not valid',
        ) &&
        validate(
          movement.isValidBeforeSanitazion(),
          'MetconMovementDescription: movement not valid',
        ) &&
        validate(
          movement.id == metconMovement.movementId,
          'MetconMovementDescription: id mismatch',
        );
  }

  @override
  bool isValid() {
    return isValidBeforeSanitazion();
  }

  @override
  void sanitize() {
    metconMovement.sanitize();
    movement.sanitize();
  }

  String get movementText {
    final count = movement.dimension == MovementDimension.time
        ? Duration(milliseconds: metconMovement.count).formatTimeShort
        : "${metconMovement.count}";

    final String unit;
    if (movement.dimension == MovementDimension.distance) {
      unit = metconMovement.distanceUnit!.displayName;
    } else if (movement.dimension == MovementDimension.time) {
      unit = "";
    } else {
      unit = movement.dimension.displayName;
    }

    final weight = metconMovement.maleWeight != null &&
            metconMovement.femaleWeight != null
        ? " @ ${metconMovement.maleWeight}/${metconMovement.femaleWeight} kg"
        : "";

    return "${movement.name}: $count $unit $weight";
  }
}
