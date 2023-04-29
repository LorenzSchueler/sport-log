import 'package:sport_log/api/api.dart';
import 'package:sport_log/models/cardio/cardio_session.dart';
import 'package:sport_log/models/cardio/route.dart';

class RouteApi extends Api<Route> {
  factory RouteApi() => _instance;

  RouteApi._();

  static final _instance = RouteApi._();

  @override
  Route fromJson(Map<String, dynamic> json) => Route.fromJson(json);

  @override
  final route = '/route';
}

class CardioSessionApi extends Api<CardioSession> {
  factory CardioSessionApi() => _instance;

  CardioSessionApi._();

  static final _instance = CardioSessionApi._();

  @override
  CardioSession fromJson(Map<String, dynamic> json) =>
      CardioSession.fromJson(json);

  @override
  final route = '/cardio_session';
}
