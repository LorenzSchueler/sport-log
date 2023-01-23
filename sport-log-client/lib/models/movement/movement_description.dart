import 'package:json_annotation/json_annotation.dart';
import 'package:sport_log/models/entity_interfaces.dart';
import 'package:sport_log/models/movement/movement.dart';

part 'movement_description.g.dart';

@JsonSerializable()
class MovementDescription extends CompoundEntity {
  MovementDescription({
    required this.movement,
    required this.hasReference,
  });

  MovementDescription.defaultValue()
      : movement = Movement.defaultValue(),
        hasReference = false;

  factory MovementDescription.fromJson(Map<String, dynamic> json) =>
      _$MovementDescriptionFromJson(json);

  Movement movement;
  bool hasReference;

  @override
  Map<String, dynamic> toJson() => _$MovementDescriptionToJson(this);

  @override
  MovementDescription clone() => MovementDescription(
        movement: movement.clone(),
        hasReference: hasReference,
      );

  @override
  bool isValidBeforeSanitation() {
    return movement.isValidBeforeSanitation();
  }

  @override
  bool isValid() {
    return isValidBeforeSanitation() && movement.isValid();
  }

  @override
  void sanitize() {
    movement.sanitize();
  }

  @override
  bool operator ==(Object other) =>
      other is MovementDescription &&
      other.hasReference == hasReference &&
      other.movement == movement;

  @override
  int get hashCode => Object.hash(hasReference, movement);

  static bool areTheSame(MovementDescription m1, MovementDescription m2) =>
      m1.movement.id == m2.movement.id;
}
