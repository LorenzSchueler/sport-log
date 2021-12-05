abstract class Routes {
  static const landing = '/landing';
  static const login = '/login';
  static const registration = '/register';
  static const workout = '/workout';
  static const metcon = _MetconRoutes();
  static const movement = _MovementRoutes();
  static const cardio = _CardioRoutes();
  static const strength = _StrengthRoutes();
  static const diary = _DiaryRoutes();
}

class _MetconRoutes {
  const _MetconRoutes();

  final String overview = '/metcon/overview';
  final String edit = '/metcon/edit';
}

class _MovementRoutes {
  const _MovementRoutes();

  final String overview = '/movement/overview';
  final String edit = '/movement/edit';
}

class _CardioRoutes {
  const _CardioRoutes();

  final String overview = '/cardio/overview';
  final String tracking_settings = '/cardio/tracking_settings';
  final String tracking = '/cardio/tracking';
  final String route_planning = '/cardio/route_planning';
  final String data_input = '/cardio/data_input';
}

class _StrengthRoutes {
  const _StrengthRoutes();

  final String details = '/strength/details';
  final String edit = '/strength/edit';
}

class _DiaryRoutes {
  const _DiaryRoutes();

  final String edit = '/diary/edit';
}
