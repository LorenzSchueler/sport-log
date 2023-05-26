import 'package:json_annotation/json_annotation.dart';
import 'package:sport_log/database/db_interfaces.dart';
import 'package:sport_log/helpers/extensions/date_time_extension.dart';
import 'package:sport_log/helpers/extensions/formatting.dart';
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

  factory MetconMovementDescription.fromJson(Map<String, dynamic> json) =>
      _$MetconMovementDescriptionFromJson(json);

  MetconMovement metconMovement;
  Movement movement;

  @override
  Map<String, dynamic> toJson() => _$MetconMovementDescriptionToJson(this);

  @override
  MetconMovementDescription clone() => MetconMovementDescription(
        metconMovement: metconMovement.clone(),
        movement: movement.clone(),
      );

  @override
  bool isValidBeforeSanitation() {
    return metconMovement.isValidBeforeSanitation() &&
        movement.isValid() &&
        validate(
          movement.id == metconMovement.movementId,
          'MetconMovementDescription: id mismatch',
        );
  }

  @override
  bool isValid() {
    return isValidBeforeSanitation() && metconMovement.isValid();
  }

  @override
  void sanitize() {
    metconMovement.sanitize();
    movement.sanitize();
  }

  String get countUnitWeight {
    final count = movement.dimension == MovementDimension.time
        ? Duration(milliseconds: metconMovement.count).formatTimeShort
        : "${metconMovement.count}";

    final String unit;
    if (movement.dimension == MovementDimension.distance) {
      unit = metconMovement.distanceUnit!.name;
    } else if (movement.dimension == MovementDimension.time) {
      unit = "";
    } else {
      unit = movement.dimension.name;
    }

    final weight = metconMovement.maleWeight != null &&
            metconMovement.femaleWeight != null
        ? " @ ${formatWeight(metconMovement.maleWeight!, metconMovement.femaleWeight)}"
        : "";

    return "$count $unit $weight";
  }
}
