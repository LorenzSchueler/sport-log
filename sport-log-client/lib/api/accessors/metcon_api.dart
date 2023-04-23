import 'package:sport_log/api/api.dart';
import 'package:sport_log/models/metcon/all.dart';

class MetconSessionApi extends Api<MetconSession> {
  @override
  MetconSession fromJson(Map<String, dynamic> json) =>
      MetconSession.fromJson(json);

  @override
  final route = '/metcon_session';
}

class MetconApi extends Api<Metcon> {
  @override
  Metcon fromJson(Map<String, dynamic> json) => Metcon.fromJson(json);

  @override
  final route = '/metcon';
}

class MetconMovementApi extends Api<MetconMovement> {
  @override
  MetconMovement fromJson(Map<String, dynamic> json) =>
      MetconMovement.fromJson(json);

  @override
  final route = '/metcon_movement';
}
