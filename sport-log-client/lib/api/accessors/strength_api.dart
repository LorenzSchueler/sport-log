import 'package:sport_log/api/api.dart';
import 'package:sport_log/models/strength/all.dart';

class StrengthSessionApi extends Api<StrengthSession> {
  @override
  StrengthSession fromJson(Map<String, dynamic> json) =>
      StrengthSession.fromJson(json);

  @override
  final route = '/strength_session';
}

class StrengthSetApi extends Api<StrengthSet> {
  @override
  StrengthSet fromJson(Map<String, dynamic> json) => StrengthSet.fromJson(json);

  @override
  final route = '/strength_set';
}
