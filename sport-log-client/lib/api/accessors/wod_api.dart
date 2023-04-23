import 'package:sport_log/api/api.dart';
import 'package:sport_log/models/wod/wod.dart';

class WodApi extends Api<Wod> {
  @override
  Wod fromJson(Map<String, dynamic> json) => Wod.fromJson(json);

  @override
  final route = '/wod';
}
