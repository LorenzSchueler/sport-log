part of '../api.dart';

class StrengthSessionApi extends ApiAccessor<StrengthSession> {
  @override
  StrengthSession fromJson(Map<String, dynamic> json) =>
      StrengthSession.fromJson(json);

  @override
  String get singularRoute => version + '/strength_session';

  @override
  Map<String, dynamic> toJson(StrengthSession object) => object.toJson();
}

class StrengthSetApi extends ApiAccessor<StrengthSet> {
  @override
  StrengthSet fromJson(Map<String, dynamic> json) => StrengthSet.fromJson(json);

  @override
  String get singularRoute => version + '/strength_set';

  @override
  Map<String, dynamic> toJson(StrengthSet object) => object.toJson();
}
