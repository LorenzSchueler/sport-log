import 'dart:typed_data';

import 'package:http/http.dart';
import 'package:sport_log/api/api.dart';
import 'package:sport_log/config.dart';
import 'package:sport_log/models/server_version/server_version.dart';

class AppApi {
  factory AppApi() => _instance;

  AppApi._();

  static final _instance = AppApi._();

  Future<ApiResult<UpdateInfo>> getUpdateInfo() {
    final uri = Api.uriFromRoute("/app/info?git_ref=${Config.gitRef}");
    final request = Request("get", uri)..headers.addAll(ApiHeaders.basicAuth);
    return request.toApiResultWithValue(
      (json) => UpdateInfo.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResult<Uint8List>> downloadUpdate() {
    const format = "apk";
    const build = Config.debugMode ? "debug" : "release";
    final flavor = Config.instance.flavor;
    final uri = Api.uriFromRoute(
      "/app/download?format=$format&build=$build&flavor=$flavor",
    );
    final request = Request("get", uri)..headers.addAll(ApiHeaders.basicAuth);
    return request.toBytes();
  }
}
