part of '../api.dart';

class MetconSessionApi extends Api<MetconSession> {
  @override
  MetconSession _fromJson(Map<String, dynamic> json) =>
      MetconSession.fromJson(json);

  @override
  String get _singularRoute => apiVersion + '/metcon_session';
}

class MetconApi extends Api<Metcon> {
  @override
  Metcon _fromJson(Map<String, dynamic> json) => Metcon.fromJson(json);

  @override
  String get _singularRoute => apiVersion + '/metcon';
}

class MetconMovementApi extends Api<MetconMovement> {
  @override
  MetconMovement _fromJson(Map<String, dynamic> json) =>
      MetconMovement.fromJson(json);

  @override
  String get _singularRoute => apiVersion + '/metcon_movement';
}
