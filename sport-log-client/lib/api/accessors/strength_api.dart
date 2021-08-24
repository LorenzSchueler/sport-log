part of '../api.dart';

extension StrengthRoutes on Api {
  // Strength Sessions

  ApiResult<void> createStrengthSession(StrengthSession ss) async {
    return _post(BackendRoutes.strengthSession, ss);
  }

  ApiResult<void> createStrengthSessions(List<StrengthSession> sss) async {
    return _post(BackendRoutes.strengthSession, sss);
  }

  ApiResult<List<StrengthSession>> getStrengthSessions() async {
    return _getMultiple(BackendRoutes.strengthSession,
        fromJson: (json) => StrengthSession.fromJson(json));
  }

  ApiResult<StrengthSession> getStrengthSession(Int64 id) async {
    return _getSingle(BackendRoutes.strengthSession + '/$id',
        fromJson: (json) => StrengthSession.fromJson(json));
  }

  ApiResult<void> updateStrengthSession(StrengthSession ss) async {
    return _put(BackendRoutes.strengthSession, ss);
  }

  ApiResult<void> updateStrengthSessions(List<StrengthSession> sss) async {
    return _put(BackendRoutes.strengthSession, sss);
  }

  // Strength Sets

  ApiResult<void> createStrengthSet(StrengthSet ss) async {
    return _post(BackendRoutes.strengthSet, ss);
  }

  ApiResult<void> createStrengthSets(List<StrengthSet> sss) async {
    return _post(BackendRoutes.strengthSet, sss);
  }

  ApiResult<List<StrengthSet>> getStrengthSets() async {
    return _getMultiple(BackendRoutes.strengthSet,
        fromJson: (json) => StrengthSet.fromJson(json));
  }

  ApiResult<StrengthSet> getStrengthSet(Int64 id) async {
    return _getSingle(BackendRoutes.strengthSet + '/$id',
        fromJson: (json) => StrengthSet.fromJson(json));
  }

  ApiResult<List<StrengthSet>> getStrengthSetsByStrengthSession(
      Int64 id) async {
    return _getMultiple(BackendRoutes.strengthSetsByStrengthSession(id),
        fromJson: (json) => StrengthSet.fromJson(json));
  }

  ApiResult<void> updateStrengthSet(StrengthSet set) async {
    return _put(BackendRoutes.strengthSet, set);
  }

  ApiResult<void> updateStrengthSets(List<StrengthSet> sets) async {
    return _put(BackendRoutes.strengthSet, sets);
  }
}
