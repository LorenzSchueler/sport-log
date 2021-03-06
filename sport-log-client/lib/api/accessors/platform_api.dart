part of '../api.dart';

class PlatformApi extends Api<Platform> {
  @override
  Platform _fromJson(Map<String, dynamic> json) => Platform.fromJson(json);

  @override
  String get _singularRoute => '$apiVersion/platform';
}

class PlatformCredentialApi extends Api<PlatformCredential> {
  @override
  PlatformCredential _fromJson(Map<String, dynamic> json) =>
      PlatformCredential.fromJson(json);

  @override
  String get _singularRoute => '$apiVersion/platform_credential';
}
