part of '../api.dart';

class UserApi with ApiLogging, ApiHelpers {
  final String route = version + '/user';

  ApiResult<User> getSingle(String username, String password) {
    return ApiResultFromRequest.fromRequestWithValue<User>((client) async {
      _logRequest('GET', route);
      final response = await client.get(
        UriFromRoute.fromRoute(route),
        headers: _ApiHeaders._basicAuth(username, password),
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
      _logRequest('POST', route, body);
      final response = await client.post(
        UriFromRoute.fromRoute(route),
        headers: _ApiHeaders._jsonContentType,
        body: jsonEncode(body),
      );
      _logResponse(response);
      return response;
    });
  }

  ApiResult<void> putSingle(User user) async {
    return ApiResultFromRequest.fromRequest((client) async {
      final body = user.toJson();
      _logRequest('PUT', route, body);
      final response = await client.put(
        UriFromRoute.fromRoute(route),
        headers: _ApiHeaders._defaultHeaders,
        body: jsonEncode(body),
      );
      _logResponse(response);
      return response;
    });
  }

  ApiResult<void> deleteSingle() async {
    return ApiResultFromRequest.fromRequest((client) async {
      _logRequest('DELETE', route);
      final response = await client.delete(
        UriFromRoute.fromRoute(route),
        headers: _ApiHeaders._defaultHeaders,
      );
      _logResponse(response);
      return response;
    });
  }
}
