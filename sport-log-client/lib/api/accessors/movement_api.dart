import 'package:sport_log/api/api.dart';
import 'package:sport_log/models/movement/movement.dart';

class MovementApi extends Api<Movement> {
  @override
  Movement fromJson(Map<String, dynamic> json) => Movement.fromJson(json);

  @override
  final route = '/movement';
}
