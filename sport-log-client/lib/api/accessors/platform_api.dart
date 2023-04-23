import 'package:sport_log/api/api.dart';
import 'package:sport_log/models/platform/all.dart';

class PlatformApi extends Api<Platform> {
  @override
  Platform fromJson(Map<String, dynamic> json) => Platform.fromJson(json);

  @override
  final route = '/platform';
}

class PlatformCredentialApi extends Api<PlatformCredential> {
  @override
  PlatformCredential fromJson(Map<String, dynamic> json) =>
      PlatformCredential.fromJson(json);

  @override
  final route = '/platform_credential';
}
