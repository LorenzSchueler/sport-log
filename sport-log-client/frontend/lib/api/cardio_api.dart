
part of 'api.dart';

extension CardioRoutes on Api {

  // Routes

  ApiResult<void> createRoute(Route route) async {
    return _post(BackendRoutes.route, route);
  }

  ApiResult<void> createRoutes(List<Route> routes) async {
    return _post(BackendRoutes.route, routes);
  }

  ApiResult<List<Route>> getRoutes() async {
    return _getMultiple(BackendRoutes.route,
        fromJson: (json) => Route.fromJson(json));
  }

  ApiResult<void> updateRoute(Route route) async {
    return _put(BackendRoutes.route, route);
  }

  ApiResult<void> updateRoutes(List<Route> routes) async {
    return _put(BackendRoutes.route, routes);
  }

  // Cardio Sessions

  ApiResult<void> createCardioSession(CardioSession cs) async {
    return _post(BackendRoutes.cardioSession, cs);
  }

  ApiResult<void> createCardioSessions(List<CardioSession> css) async {
    return _post(BackendRoutes.cardioSession, css);
  }

  ApiResult<List<CardioSession>> getCardioSessions() async {
    return _getMultiple(BackendRoutes.cardioSession,
        fromJson: (json) => CardioSession.fromJson(json));
  }

  ApiResult<void> updateCardioSession(CardioSession cs) async {
    return _put(BackendRoutes.cardioSession, cs);
  }

  ApiResult<void> updateCardioSessions(List<CardioSession> css) async {
    return _put(BackendRoutes.cardioSession, css);
  }
}