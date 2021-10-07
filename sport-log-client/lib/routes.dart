abstract class Routes {
  static const landing = '/landing';
  static const login = '/login';
  static const registration = '/register';
  static const workout = '/workout';
  static const metcon = _MetconRoutes();
  static const movement = _MovementRoutes();
  static const strength = _StrengthRoutes();
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

class _StrengthRoutes {
  const _StrengthRoutes();

  final String details = '/strength/details';
}
