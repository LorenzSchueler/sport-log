import 'dart:convert';

import 'package:http/http.dart';
import 'package:sport_log/api/api.dart';
import 'package:sport_log/config.dart';
import 'package:sport_log/models/user/user.dart';
import 'package:sport_log/settings.dart';

class UserApi {
  final _uri =
      Uri.parse("${Settings.instance.serverUrl}/v${Config.apiVersion}/user");

  Future<ApiResult<User>> getSingle(String username, String password) =>
      (Request("get", _uri)
            ..headers.addAll(ApiHeaders.basicAuthFromParts(username, password)))
          .toApiResultWithValue(
        (dynamic json) =>
            User.fromJson(json as Map<String, dynamic>)..password = password,
      );

  Future<ApiResult<void>> postSingle(User user) => (Request("post", _uri)
        ..body = jsonEncode(user.toJson())
        ..headers.addAll(ApiHeaders.contentTypeJson))
      .toApiResult();

  Future<ApiResult<void>> putSingle(User user) => (Request("put", _uri)
        ..body = jsonEncode(user.toJson())
        ..headers.addAll(ApiHeaders.basicAuthContentTypeJson))
      .toApiResult();

  Future<ApiResult<void>> deleteSingle() => (Request("delete", _uri)
        ..headers.addAll(ApiHeaders.basicAuthContentTypeJson))
      .toApiResult();
}
