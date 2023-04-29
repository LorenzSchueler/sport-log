import 'package:sport_log/api/api.dart';
import 'package:sport_log/models/strength/all.dart';

class StrengthSessionApi extends Api<StrengthSession> {
  factory StrengthSessionApi() => _instance;

  StrengthSessionApi._();

  static final _instance = StrengthSessionApi._();

  @override
  StrengthSession fromJson(Map<String, dynamic> json) =>
      StrengthSession.fromJson(json);

  @override
  final route = '/strength_session';
}

class StrengthSetApi extends Api<StrengthSet> {
  factory StrengthSetApi() => _instance;

  StrengthSetApi._();

  static final _instance = StrengthSetApi._();

  @override
  StrengthSet fromJson(Map<String, dynamic> json) => StrengthSet.fromJson(json);

  @override
  final route = '/strength_set';
}
