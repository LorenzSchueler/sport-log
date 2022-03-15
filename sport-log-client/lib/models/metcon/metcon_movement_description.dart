import 'package:json_annotation/json_annotation.dart';
import 'package:sport_log/database/db_interfaces.dart';
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
  bool isValidIgnoreEmptyNotNull() {
    return validate(
          metconMovement.isValid(),
          'MetconMovementDescription: metcon movement not valid',
        ) &&
        validate(
          movement.isValid(),
          'MetconMovementDescription: movement not valid',
        ) &&
        validate(
          movement.id == metconMovement.movementId,
          'MetconMovementDescription: id mismatch',
        );
  }

  @override
  bool isValid() {
    return isValidIgnoreEmptyNotNull();
  }

  @override
  void setEmptyToNull() {
    metconMovement.setEmptyToNull();
    movement.setEmptyToNull();
  }

  String get movementText {
    String text = "${movement.name} ${metconMovement.count} ";
    text += movement.dimension == MovementDimension.distance
        ? metconMovement.distanceUnit!.displayName
        : movement.dimension.displayName;
    if (metconMovement.maleWeight != null &&
        metconMovement.femaleWeight != null) {
      text +=
          " @ ${metconMovement.maleWeight}/${metconMovement.femaleWeight} kg";
    }
    return text;
  }
}
