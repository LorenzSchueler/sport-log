part of '../api.dart';

class UserApi with ApiLogging, ApiHelpers {
  final String route = version + '/user';

  ApiResult<User> getSingle(String username, String password) {
    return ApiResultFromRequest.fromRequestWithValue<User>((client) async {
      final headers = _ApiHeaders._basicAuth(username, password);
      _logRequest('GET', route, headers);
      final response = await client.get(
        UriFromRoute.fromRoute(route),
        headers: headers,
      );
      _logResponse(response);
      return response;
    },
        (dynamic json) =>
            User.fromJson(json as Map<String, dynamic>)..password = password);
  }

  ApiResult<void> postSingle(User user) async {
    return ApiResultFromRequest.fromRequest((client) async {
      final body = user.toJson();
      const headers = _ApiHeaders._jsonContentType;
      _logRequest('POST', route, headers, body);
      final response = await client.post(
        UriFromRoute.fromRoute(route),
        headers: headers,
        body: jsonEncode(body),
      );
      _logResponse(response);
      return response;
    });
  }

  ApiResult<void> putSingle(User user) async {
    return ApiResultFromRequest.fromRequest((client) async {
      final body = user.toJson();
      final headers = _ApiHeaders._defaultHeaders;
      _logRequest('PUT', route, headers, body);
      final response = await client.put(
        UriFromRoute.fromRoute(route),
        headers: headers,
        body: jsonEncode(body),
      );
      _logResponse(response);
      return response;
    });
  }

  ApiResult<void> deleteSingle() async {
    return ApiResultFromRequest.fromRequest((client) async {
      final headers = _ApiHeaders._defaultHeaders;
      _logRequest('DELETE', route, headers);
      final response = await client.delete(
        UriFromRoute.fromRoute(route),
        headers: headers,
      );
      _logResponse(response);
      return response;
    });
  }
}
