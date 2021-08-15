
part of 'api.dart';

extension PlatformRoutes on Api {
  ApiResult<List<Platform>> getPlatforms() async {
    return _get(BackendRoutes.platform);
  }

  ApiResult<void> createPlatformCredential(PlatformCredential pc) async {
    return _post(BackendRoutes.platformCredential, pc);
  }

  ApiResult<void> createPlatformCredentials(
      List<PlatformCredential> pcs) async {
    return _post(BackendRoutes.platformCredential, pcs);
  }

  ApiResult<List<PlatformCredential>> getPlatformCredentials() async {
    return _get(BackendRoutes.platformCredential);
  }

  ApiResult<void> updatePlatformCredential(PlatformCredential pc) async {
    return _put(BackendRoutes.platformCredential, pc);
  }

  ApiResult<void> updatePlatformCredentials(
      List<PlatformCredential> pcs) async {
    return _put(BackendRoutes.platformCredential, pcs);
  }
}