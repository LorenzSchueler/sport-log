part of '../api.dart';

class UserApi with ApiLogging, ApiHelpers {
  final String _route = '/user';

  String get _path => "/v${Config.apiVersion}$_route";

  Future<ApiResult<User>> getSingle(String username, String password) {
    return ApiResultFromRequest.fromRequestWithValue<User>(
      (client) async {
        final headers = _ApiHeaders._basicAuth(username, password);
        _logRequest('GET', _path, headers);
        final response = await client.get(
          UriFromRoute.fromRoute(_path),
          headers: headers,
        );
        _logResponse(response);
        return response;
      },
      (dynamic json) =>
          User.fromJson(json as Map<String, dynamic>)..password = password,
    );
  }

  Future<ApiResult<void>> postSingle(User user) async {
    return ApiResultFromRequest.fromRequest((client) async {
      final body = user.toJson();
      const headers = _ApiHeaders._jsonContentType;
      _logRequest('POST', _path, headers, body);
      final response = await client.post(
        UriFromRoute.fromRoute(_path),
        headers: headers,
        body: jsonEncode(body),
      );
      _logResponse(response);
      return response;
    });
  }

  Future<ApiResult<void>> putSingle(User user) async {
    return ApiResultFromRequest.fromRequest((client) async {
      final body = user.toJson();
      final headers = _ApiHeaders._defaultHeaders;
      _logRequest('PUT', _path, headers, body);
      final response = await client.put(
        UriFromRoute.fromRoute(_path),
        headers: headers,
        body: jsonEncode(body),
      );
      _logResponse(response);
      return response;
    });
  }

  Future<ApiResult<void>> deleteSingle() async {
    return ApiResultFromRequest.fromRequest((client) async {
      final headers = _ApiHeaders._defaultHeaders;
      _logRequest('DELETE', _path, headers);
      final response = await client.delete(
        UriFromRoute.fromRoute(_path),
        headers: headers,
      );
      _logResponse(response);
      return response;
    });
  }
}
