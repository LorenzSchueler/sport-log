part of '../api.dart';

class MovementApi extends Api<Movement> {
  @override
  Movement _fromJson(Map<String, dynamic> json) => Movement.fromJson(json);

  @override
  String get _route => '/movement';
}
