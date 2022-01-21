abstract class Routes {
  static const landing = '/landing';
  static const login = '/login';
  static const registration = '/register';
  static const timer = "/timer";
  static const map = "/map";
  static const offlineMaps = "/offline_maps";
  static const settings = "/settings";
  static const timeline = _TimelineRoutes();
  static const metcon = _MetconRoutes();
  static const movement = _MovementRoutes();
  static const cardio = _CardioRoutes();
  static const strength = _StrengthRoutes();
  static const diary = _DiaryRoutes();
}

class _MovementRoutes {
  const _MovementRoutes();

  final String overview = '/movement/overview';
  final String edit = '/movement/edit';
}

class _TimelineRoutes {
  const _TimelineRoutes();

  final String overview = '/timeline/overview';
}

class _MetconRoutes {
  const _MetconRoutes();

  final String overview = '/metcon/overview';
  final String edit = '/metcon/edit';
  final String sessionOverview = '/metcon/session_overview';
  final String sessionDetails = '/metcon/session_details';
  final String sessionEdit = '/metcon/session_edit';
}

class _CardioRoutes {
  const _CardioRoutes();

  final String overview = '/cardio/overview';
  final String trackingSettings = '/cardio/tracking_settings';
  final String tracking = '/cardio/tracking';
  final String cardioEdit = '/cardio/cardio_edit';
  final String cardioDetails = '/cardio/cardio_details';
  final String routeEdit = '/cardio/route_edit';
  final String routeOverview = '/cardio/route_overview';
}

class _StrengthRoutes {
  const _StrengthRoutes();

  final String overview = '/strength/overview';
  final String details = '/strength/details';
  final String edit = '/strength/edit';
}

class _DiaryRoutes {
  const _DiaryRoutes();

  final String overview = '/diary/overview';
  final String edit = '/diary/edit';
}
