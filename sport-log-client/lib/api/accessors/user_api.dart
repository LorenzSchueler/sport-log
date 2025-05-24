import 'dart:convert';

import 'package:http/http.dart';
import 'package:sport_log/api/api.dart';
import 'package:sport_log/models/epoch/epoch_result.dart';
import 'package:sport_log/models/user/user.dart';

class UserApi {
  factory UserApi() => _instance;

  UserApi._();

  static final _instance = UserApi._();

  final _uri = Api.uriFromRoute("/user");

  Future<ApiResult<User>> getSingle(String username, String password) =>
      (Request("get", _uri)
            ..headers.addAll(ApiHeaders.basicAuthFromParts(username, password)))
          .toApiResultWithValue(
            (Object json) =>
                User.fromJson(json as Map<String, dynamic>)
                  ..password = password,
          );

  Future<ApiResult<EpochResult>> postSingle(User user) =>
      (Request("post", _uri)
            ..body = jsonEncode(user.toJson())
            ..headers.addAll(ApiHeaders.contentTypeJson))
          .toApiResultWithValue(
            (json) => EpochResult.fromJson((json as Map).cast()),
          );

  Future<ApiResult<EpochResult>> putSingle(User user) =>
      (Request("put", _uri)
            ..body = jsonEncode(user.toJson())
            ..headers.addAll(ApiHeaders.basicAuthContentTypeJson))
          .toApiResultWithValue(
            (json) => EpochResult.fromJson((json as Map).cast()),
          );

  Future<ApiResult<void>> deleteSingle() => (Request(
    "delete",
    _uri,
  )..headers.addAll(ApiHeaders.basicAuth)).toApiResult();
}
