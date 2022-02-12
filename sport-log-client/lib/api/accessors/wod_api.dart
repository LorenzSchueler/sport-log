part of '../api.dart';

class WodApi extends ApiAccessor<Wod> {
  @override
  Wod fromJson(Map<String, dynamic> json) => Wod.fromJson(json);

  @override
  String get singularRoute => version + '/wod';
  String get x => (Wod).runtimeType.toString();
}
