part of '../api.dart';

class RouteApi extends ApiAccessor<Route> {
  @override
  Route fromJson(Map<String, dynamic> json) => Route.fromJson(json);

  @override
  String get singularRoute => version + '/route';
}

class CardioSessionApi extends ApiAccessor<CardioSession> {
  @override
  CardioSession fromJson(Map<String, dynamic> json) =>
      CardioSession.fromJson(json);

  @override
  String get singularRoute => version + '/cardio_session';
}
