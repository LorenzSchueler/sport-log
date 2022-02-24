import 'package:fixnum/fixnum.dart';
import 'package:sport_log/database/db_interfaces.dart';
import 'package:sport_log/models/movement/movement.dart';

class MovementDescription implements Validatable, HasId {
  MovementDescription({
    required this.movement,
    required this.hasReference,
  });

  MovementDescription.defaultValue(Int64 userId)
      : movement = Movement.defaultValue(userId),
        hasReference = false;

  Movement movement;
  bool hasReference;

  static bool areTheSame(MovementDescription m1, MovementDescription m2) =>
      m1.movement.id == m2.movement.id;

  @override
  bool isValid() {
    return validate(
      movement.isValid(),
      'MovementDescription: movement is not valid',
    );
  }

  @override
  Int64 get id => movement.id;

  MovementDescription copy() => MovementDescription(
        movement: movement.copy(),
        hasReference: hasReference,
      );

  @override
  bool operator ==(other) =>
      other is MovementDescription &&
      other.hasReference == hasReference &&
      other.movement == movement;

  @override
  int get hashCode => Object.hash(hasReference, movement);
}
