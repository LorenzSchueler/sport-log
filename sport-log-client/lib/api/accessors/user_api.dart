part of '../api.dart';

class UserApi with _ApiLogging {
  final String _route = '/user';

  Uri get _uri =>
      Uri.parse("${Settings.instance.serverUrl}/v${Config.apiVersion}$_route");

  Future<ApiResult<User>> getSingle(String username, String password) {
    return ApiResultFromRequest.fromRequestWithValue<User>(
      (client) async {
        final headers = _ApiHeaders._basicAuthFromParts(username, password);
        _logRequest('GET', _uri, headers);
        final response = await client.get(
          _uri,
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
      const headers = _ApiHeaders._contentTypeJson;
      _logRequest('POST', _uri, headers, body);
      final response = await client.post(
        _uri,
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
      final headers = _ApiHeaders._basicAuthContentTypeJson;
      _logRequest('PUT', _uri, headers, body);
      final response = await client.put(
        _uri,
        headers: headers,
        body: jsonEncode(body),
      );
      _logResponse(response);
      return response;
    });
  }

  Future<ApiResult<void>> deleteSingle() async {
    return ApiResultFromRequest.fromRequest((client) async {
      final headers = _ApiHeaders._basicAuthContentTypeJson;
      _logRequest('DELETE', _uri, headers);
      final response = await client.delete(
        _uri,
        headers: headers,
      );
      _logResponse(response);
      return response;
    });
  }
}
