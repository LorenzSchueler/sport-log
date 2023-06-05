import 'package:http/http.dart';
import 'package:sport_log/api/api.dart';
import 'package:sport_log/models/server_version/server_version.dart';
import 'package:sport_log/settings.dart';

class ServerVersionApi {
  factory ServerVersionApi() => _instance;

  ServerVersionApi._();

  static final _instance = ServerVersionApi._();

  Uri get _uri => Uri.parse("${Settings.instance.serverUrl}/version");

  Future<ApiResult<ServerVersion>> getServerVersion() {
    return Request("get", _uri).toApiResultWithValue(
      (json) => ServerVersion.fromJson(json as Map<String, dynamic>),
    );
  }
}
