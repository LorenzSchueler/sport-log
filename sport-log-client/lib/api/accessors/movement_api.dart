part of '../api.dart';

class MovementApi extends ApiAccessor<Movement> {
  @override
  Movement fromJson(Map<String, dynamic> json) => Movement.fromJson(json);

  @override
  String get singularRoute => version + '/movement';
}
