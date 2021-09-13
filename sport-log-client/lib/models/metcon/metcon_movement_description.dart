import 'package:sport_log/database/defs.dart';
import 'package:sport_log/models/movement/movement.dart';

import 'metcon_movement.dart';

class MetconMovementDescription implements Validatable {
  MetconMovementDescription({
    required this.metconMovement,
    required this.movement,
  });

  MetconMovement metconMovement;
  Movement movement;

  @override
  bool isValid() {
    return validate(metconMovement.isValid(),
            'MetconMovementDescription: metcon movement not valid') &&
        validate(movement.isValid(),
            'MetconMovementDescription: movement not valid') &&
        validate(movement.id == metconMovement.movementId,
            'MetconMovementDescription: id mismatch');
  }
}
