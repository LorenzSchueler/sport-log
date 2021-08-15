
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
  static const strengthSet = _version + '/strength_set';
  static const strengthSession = _version + '/strength_session';
  static const platform = _version + '/platform';
  static const platformCredential = _version + '/platform_credential';

  static String metconMovementByMetcon(Int64 id) =>
      _version + '/metcon_movement/metcon/${id.toString()}';

  static String strengthSetsByStrengthSession(Int64 id) =>
      _version + '/strength_set/strength_session/${id.toString()}';
}
