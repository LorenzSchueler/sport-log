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
  final String cardio_edit = '/cardio/cardio_edit';
  final String cardio_details = '/cardio/cardio_details';
  final String route_edit = '/cardio/route_edit';
  final String route_overview = '/cardio/route_overview';
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
