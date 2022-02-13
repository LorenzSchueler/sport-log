part of '../api.dart';

class RouteApi extends Api<Route> {
  @override
  Route _fromJson(Map<String, dynamic> json) => Route.fromJson(json);

  @override
  String get _singularRoute => version + '/route';
}

class CardioSessionApi extends Api<CardioSession> {
  @override
  CardioSession _fromJson(Map<String, dynamic> json) =>
      CardioSession.fromJson(json);

  @override
  String get _singularRoute => version + '/cardio_session';
}
