import 'package:fixnum/fixnum.dart';

import 'movement.dart';

class MovementDescription {
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
}
