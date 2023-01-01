part of '../api.dart';

class RouteApi extends Api<Route> {
  @override
  Route _fromJson(Map<String, dynamic> json) => Route.fromJson(json);

  @override
  String get _route => '/route';
}

class CardioSessionApi extends Api<CardioSession> {
  @override
  CardioSession _fromJson(Map<String, dynamic> json) =>
      CardioSession.fromJson(json);

  @override
  String get _route => '/cardio_session';
}
