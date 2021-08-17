
import 'package:sport_log/models/cardio/cardio_session.dart';
import 'package:sport_log/models/cardio/route.dart';
import 'package:sport_log/helpers/update_validatable.dart';

class CardioSessionDescription implements Validatable {
  CardioSessionDescription({
    required this.cardioSession,
    required this.route,
  });

  CardioSession cardioSession;
  Route? route;

  @override
  bool isValid() {
    return cardioSession.isValid()
        && (route == null || route!.isValid())
        && (route == null || cardioSession.routeId != null)
        && (route == null || cardioSession.routeId! == route!.id);
  }
}