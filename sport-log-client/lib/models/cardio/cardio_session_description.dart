import 'package:sport_log/helpers/validation.dart';
import 'package:sport_log/models/cardio/cardio_session.dart';
import 'package:sport_log/models/cardio/route.dart';

class CardioSessionDescription implements Validatable {
  CardioSessionDescription({
    required this.cardioSession,
    required this.route,
  });

  CardioSession cardioSession;
  Route? route;

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
                'CardioSessionDescription: route id mismatch'));
  }
}
