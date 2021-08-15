
part of 'api.dart';

extension MetconRoutes on Api {

  // Metcon Session

  ApiResult<void> createMetconSession(MetconSession ms) async {
    return _post(BackendRoutes.metconSession, ms);
  }

  ApiResult<void> createMetconSessions(
      List<MetconSession> mss) async {
    return _post(BackendRoutes.metconSession, mss);
  }

  ApiResult<List<MetconSession>> getMetconSessions() async {
    return _get(BackendRoutes.metconSession);
  }

  ApiResult<void> updateMetconSession(MetconSession ms) async {
    return _put(BackendRoutes.metconSession, ms);
  }

  ApiResult<void> updateMetconSessions(
      List<MetconSession> mss) async {
    return _put(BackendRoutes.metconSession, mss);
  }

  // Metcon

  ApiResult<void> createMetcon(Metcon metcon) async {
    return _post(BackendRoutes.metcon, metcon);
  }

  ApiResult<void> createMetcons(List<Metcon> metcons) async {
    return _post(BackendRoutes.metcon, metcons);
  }

  ApiResult<List<Metcon>> getMetcons() async {
    return _get(BackendRoutes.metcon);
  }

  ApiResult<void> updateMetcon(Metcon metcon) async {
    return _put(BackendRoutes.metcon, metcon);
  }

  ApiResult<void> updateMetcons(List<Metcon> metcons) async {
    return _put(BackendRoutes.metcon, metcons);
  }

  // Metcon Movement

  ApiResult<void> createMetconMovement(MetconMovement mm) async {
    return _post(BackendRoutes.metconMovement, mm);
  }

  ApiResult<void> createMetconMovements(List<MetconMovement> mms) async {
    return _post(BackendRoutes.metconMovement, mms);
  }

  ApiResult<List<MetconMovement>> getMetconMovements() async {
    return _get(BackendRoutes.metconMovement);
  }

  ApiResult<List<MetconMovement>> getMetconMovementsByMetcon(Int64 id) async {
    return _get(BackendRoutes.metconMovementByMetcon(id));
  }

  ApiResult<void> updateMetconMovement(MetconMovement mm) async {
    return _put(BackendRoutes.metconMovement, mm);
  }

  ApiResult<void> updateMetconMovements(List<MetconMovement> mms) async {
    return _put(BackendRoutes.metconMovement, mms);
  }
}