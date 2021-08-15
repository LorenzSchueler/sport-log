
import 'package:fixnum/fixnum.dart';

abstract class BackendRoutes {
  static const _version = '/v1';
  static const user = _version + 'user';
  static const movement = _version + '/movement';
  static const metconSession = _version + '/metcon_session';
  static const metcon = _version + '/metcon';
  static const metconMovement = _version + '/metcon_movement';
  static const route = _version + '/route';
  static const cardioSession = _version + '/cardio_session';
  static const diary = _version + '/diary';
  static const wod = _version + '/wod';

  static String metconMovementByMetcon(Int64 id) =>
      _version + metconMovement + '/metcon/${id.toString()}';
}
