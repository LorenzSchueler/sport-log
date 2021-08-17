
part of 'api.dart';

extension PlatformRoutes on Api {
  ApiResult<List<Platform>> getPlatforms() async {
    return _getMultiple(BackendRoutes.platform,
        fromJson: (json) => Platform.fromJson(json));
  }

  ApiResult<Platform> getPlatform(Int64 id) async {
    return _getSingle(BackendRoutes.platform + '/$id',
        fromJson: (json) => Platform.fromJson(json));
  }

  ApiResult<void> createPlatformCredential(PlatformCredential pc) async {
    return _post(BackendRoutes.platformCredential, pc);
  }

  ApiResult<void> createPlatformCredentials(
      List<PlatformCredential> pcs) async {
    return _post(BackendRoutes.platformCredential, pcs);
  }

  ApiResult<List<PlatformCredential>> getPlatformCredentials() async {
    return _getMultiple(BackendRoutes.platformCredential,
        fromJson: (json) => PlatformCredential.fromJson(json));
  }

  ApiResult<PlatformCredential> getPlatformCredential(Int64 id) async {
    return _getSingle(BackendRoutes.platformCredential + '/$id',
        fromJson: (json) => PlatformCredential.fromJson(json));
  }

  ApiResult<void> updatePlatformCredential(PlatformCredential pc) async {
    return _put(BackendRoutes.platformCredential, pc);
  }

  ApiResult<void> updatePlatformCredentials(
      List<PlatformCredential> pcs) async {
    return _put(BackendRoutes.platformCredential, pcs);
  }
}