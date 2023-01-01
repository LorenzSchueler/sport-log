part of '../api.dart';

class StrengthSessionApi extends Api<StrengthSession> {
  @override
  StrengthSession _fromJson(Map<String, dynamic> json) =>
      StrengthSession.fromJson(json);

  @override
  String get _route => '/strength_session';
}

class StrengthSetApi extends Api<StrengthSet> {
  @override
  StrengthSet _fromJson(Map<String, dynamic> json) =>
      StrengthSet.fromJson(json);

  @override
  String get _route => '/strength_set';
}
