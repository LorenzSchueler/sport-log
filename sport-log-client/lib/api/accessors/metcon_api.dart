import 'package:sport_log/api/api.dart';
import 'package:sport_log/models/metcon/all.dart';

class MetconSessionApi extends Api<MetconSession> {
  factory MetconSessionApi() => _instance;

  MetconSessionApi._();

  static final _instance = MetconSessionApi._();

  @override
  MetconSession fromJson(Map<String, dynamic> json) =>
      MetconSession.fromJson(json);

  @override
  final route = '/metcon_session';
}

class MetconApi extends Api<Metcon> {
  factory MetconApi() => _instance;

  MetconApi._();

  static final _instance = MetconApi._();

  @override
  Metcon fromJson(Map<String, dynamic> json) => Metcon.fromJson(json);

  @override
  final route = '/metcon';
}

class MetconMovementApi extends Api<MetconMovement> {
  factory MetconMovementApi() => _instance;

  MetconMovementApi._();

  static final _instance = MetconMovementApi._();

  @override
  MetconMovement fromJson(Map<String, dynamic> json) =>
      MetconMovement.fromJson(json);

  @override
  final route = '/metcon_movement';
}
