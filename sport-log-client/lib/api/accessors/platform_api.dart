part of '../api.dart';

class PlatformApi extends Api<Platform> {
  @override
  Platform _fromJson(Map<String, dynamic> json) => Platform.fromJson(json);

  @override
  String get _singularRoute => version + '/platform';

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

class PlatformCredentialApi extends Api<PlatformCredential> {
  @override
  PlatformCredential _fromJson(Map<String, dynamic> json) =>
      PlatformCredential.fromJson(json);

  @override
  String get _singularRoute => version + '/platform_credential';
}
