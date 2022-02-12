part of '../api.dart';

class PlatformApi extends ApiAccessor<Platform> {
  @override
  Platform fromJson(Map<String, dynamic> json) => Platform.fromJson(json);

  @override
  String get singularRoute => version + '/platform';

  @override
  ApiResult<void> postSingle(Platform object) => throw UnimplementedError();

  @override
  ApiResult<void> postMultiple(List<Platform> objects) =>
      throw UnimplementedError();

  @override
  ApiResult<void> putSingle(Platform object) => throw UnimplementedError();

  @override
  ApiResult<void> putMultiple(List<Platform> objects) =>
      throw UnimplementedError();
}

class PlatformCredentialApi extends ApiAccessor<PlatformCredential> {
  @override
  PlatformCredential fromJson(Map<String, dynamic> json) =>
      PlatformCredential.fromJson(json);

  @override
  String get singularRoute => version + '/platform_credential';
}
