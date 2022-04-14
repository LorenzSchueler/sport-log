part of '../api.dart';

class RouteApi extends Api<Route> {
  @override
  Route _fromJson(Map<String, dynamic> json) => Route.fromJson(json);

  @override
  String get _singularRoute => apiVersion + '/route';
}

class CardioSessionApi extends Api<CardioSession> {
  @override
  CardioSession _fromJson(Map<String, dynamic> json) =>
      CardioSession.fromJson(json);

  @override
  String get _singularRoute => apiVersion + '/cardio_session';
}
