
part of 'api.dart';

extension WodRoutes on Api {
  ApiResult<void> createWod(Wod wod) async {
    return _post(BackendRoutes.wod, wod);
  }

  ApiResult<void> createWods(List<Wod> wods) async {
    return _post(BackendRoutes.wod, wods);
  }

  ApiResult<List<Wod>> getWods() async {
    return _getMultiple(BackendRoutes.wod,
        fromJson: (json) => Wod.fromJson(json));
  }

  ApiResult<void> updateWod(Wod wod) async {
    return _put(BackendRoutes.wod, wod);
  }

  ApiResult<void> updateWods(List<Wod> wods) async {
    return _put(BackendRoutes.wod, wods);
  }
}
