import 'package:fixnum/fixnum.dart';
import 'package:sport_log/database/db_interfaces.dart';
import 'package:sport_log/models/cardio/all.dart';
import 'package:sport_log/models/movement/movement.dart';

class CardioSessionDescription implements Validatable, HasId {
  CardioSessionDescription({
    required this.cardioSession,
    required this.route,
    required this.movement,
  });

  CardioSession cardioSession;
  Route? route;
  Movement movement;

  @override
  bool isValid() {
    return cardioSession.isValid() &&
        (route == null ||
            validate(route!.isValid(),
                'CardioSessionDescription: route is not valid')) &&
        (route == null ||
            validate(cardioSession.routeId != null,
                'CardioSessionDescription: cardio session route id is null')) &&
        (route == null ||
            validate(cardioSession.routeId! == route!.id,
                'CardioSessionDescription: route id mismatch')) &&
        (validate(movement.isValid(),
            'CardioSessionDescription: movement is not valid')) &&
        (validate(cardioSession.movementId == movement.id,
            'CardioSessionDescription: movement id mismatch'));
  }

  @override
  Int64 get id => cardioSession.id;
}
