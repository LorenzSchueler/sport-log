import 'package:sport_log/api/api.dart';
import 'package:sport_log/models/wod/wod.dart';

class WodApi extends Api<Wod> {
  factory WodApi() => _instance;

  WodApi._();

  static final _instance = WodApi._();

  @override
  Wod fromJson(Map<String, dynamic> json) => Wod.fromJson(json);

  @override
  final route = '/wod';
}
