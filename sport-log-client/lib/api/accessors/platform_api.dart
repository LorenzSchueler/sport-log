import 'package:sport_log/api/api.dart';
import 'package:sport_log/models/platform/all.dart';

class PlatformApi extends Api<Platform> {
  factory PlatformApi() => _instance;

  PlatformApi._();

  static final _instance = PlatformApi._();

  @override
  Platform fromJson(Map<String, dynamic> json) => Platform.fromJson(json);

  @override
  final route = '/platform';
}

class PlatformCredentialApi extends Api<PlatformCredential> {
  factory PlatformCredentialApi() => _instance;

  PlatformCredentialApi._();

  static final _instance = PlatformCredentialApi._();

  @override
  PlatformCredential fromJson(Map<String, dynamic> json) =>
      PlatformCredential.fromJson(json);

  @override
  final route = '/platform_credential';
}
