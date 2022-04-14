part of '../api.dart';

class WodApi extends Api<Wod> {
  @override
  Wod _fromJson(Map<String, dynamic> json) => Wod.fromJson(json);

  @override
  String get _singularRoute => apiVersion + '/wod';
  String get x => (Wod).runtimeType.toString();
}
