import 'package:fixnum/fixnum.dart';
import 'package:sport_log/database/defs.dart';

import 'movement.dart';

class MovementDescription implements Validatable {
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
        movement.isValid(), 'MovementDescription: movement is not valid');
  }
}
