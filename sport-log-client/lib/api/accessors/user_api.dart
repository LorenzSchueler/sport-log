part of '../api.dart';

class UserApi with ApiLogging, ApiHelpers {
  final String route = version + '/user';

  ApiResult<User> getSingle(String username, String password) {
    return _errorHandling<User>((client) async {
      _logRequest('GET', route);
      final response = await client.get(
        _uri(route),
        headers: _ApiHeaders._makeAuthorizedHeader(username, password),
      );
      _logResponse(response);
      if (response.statusCode == 401) {
        return Failure(ApiError.loginFailed);
      } else if (response.statusCode < 200 || response.statusCode >= 300) {
        return Failure(ApiError.unknown);
      } else {
        final user = User.fromJson(
            jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>)
          ..password = password;
        return Success(user);
      }
    });
  }

  ApiResult<void> postSingle(User user) async {
    return _errorHandling((client) async {
      final body = user.toJson();
      _logRequest('POST', route, body);
      final response = await client.post(
        _uri(route),
        headers: _ApiHeaders._jsonContentTypeHeader,
        body: jsonEncode(body),
      );
      _logResponse(response);
      if (response.statusCode == 409) {
        return Failure(ApiError.usernameTaken);
      } else if (response.statusCode < 200 || response.statusCode >= 300) {
        return Failure(ApiError.unknown);
      } else {
        return Success(null);
      }
    });
  }

  ApiResult<void> putSingle(User user) async {
    assert(Settings.instance.userId! == user.id);
    return _errorHandling((client) async {
      final body = user.toJson();
      _logRequest('PUT', route, body);
      final response = await client.put(
        _uri(route),
        headers: _ApiHeaders._defaultHeaders,
        body: jsonEncode(body),
      );
      _logResponse(response);
      if (response.statusCode == 409) {
        return Failure(ApiError.usernameTaken);
      } else if (response.statusCode < 200 || response.statusCode >= 300) {
        return Failure(ApiError.unknown);
      } else {
        return Success(null);
      }
    });
  }

  ApiResult<void> deleteSingle() async {
    return _errorHandling((client) async {
      _logRequest('DELETE', route);
      final response = await client.delete(
        _uri(route),
        headers: _ApiHeaders._defaultHeaders,
      );
      _logResponse(response);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return Failure(ApiError.unknown);
      } else {
        return Success(null);
      }
    });
  }
}
