import 'package:sport_log/api/api.dart';
import 'package:sport_log/models/cardio/cardio_session.dart';
import 'package:sport_log/models/cardio/route.dart';

class RouteApi extends Api<Route> {
  @override
  Route fromJson(Map<String, dynamic> json) => Route.fromJson(json);

  @override
  final route = '/route';
}

class CardioSessionApi extends Api<CardioSession> {
  @override
  CardioSession fromJson(Map<String, dynamic> json) =>
      CardioSession.fromJson(json);

  @override
  final route = '/cardio_session';
}
