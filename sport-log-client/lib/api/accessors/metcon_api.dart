part of '../api.dart';

class MetconSessionApi extends ApiAccessor<MetconSession> {
  @override
  MetconSession fromJson(Map<String, dynamic> json) =>
      MetconSession.fromJson(json);

  @override
  String get singularRoute => version + '/metcon_session';

  @override
  Map<String, dynamic> toJson(MetconSession object) => object.toJson();
}

class MetconApi extends ApiAccessor<Metcon> {
  @override
  Metcon fromJson(Map<String, dynamic> json) => Metcon.fromJson(json);

  @override
  String get singularRoute => version + '/metcon';

  @override
  Map<String, dynamic> toJson(Metcon object) => object.toJson();
}

class MetconMovementApi extends ApiAccessor<MetconMovement> {
  @override
  MetconMovement fromJson(Map<String, dynamic> json) =>
      MetconMovement.fromJson(json);

  @override
  String get singularRoute => version + '/metcon_movement';

  @override
  Map<String, dynamic> toJson(MetconMovement object) => object.toJson();
}
