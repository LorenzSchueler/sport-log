part of '../api.dart';

extension UserRoutes on Api {
  ApiResult<void> createUser(User user) async {
    final result = await _post(BackendRoutes.user, user,
        headers: _jsonContentTypeHeader, mapBadStatusToApiError: (statusCode) {
      if (statusCode == 409) {
        return ApiError.usernameTaken;
      }
    });
    if (result.isSuccess) {
      UserState.instance.setUser(user);
    }
    return result;
  }

  ApiResult<User> getUser(String username, String password) async {
    final result = await _getSingle<User>(BackendRoutes.user,
        fromJson: (json) => User.fromJson(json),
        headers: _makeAuthorizedHeader(username, password),
        mapBadStatusToApiError: (statusCode) {
          if (statusCode == 401) {
            return ApiError.loginFailed;
          }
        });
    if (result.isSuccess) {
      final user = result.success..password = password;
      UserState.instance.setUser(user);
    }
    return result;
  }

  ApiResult<void> updateUser(User user) async {
    final result = await _put(BackendRoutes.user, user);
    if (result.isSuccess) {
      UserState.instance.setUser(user);
    }
    return result;
  }

  ApiResult<void> deleteUser() async {
    return _errorHandling((client) async {
      final route = BackendRoutes.user;
      _logRequest('DELETE', route);
      final response =
          await client.delete(_uri(route), headers: _authorizedHeader);
      _logResponse(response);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        UserState.instance.deleteUser();
        return Success(null);
      }
      _handleUnknownStatusCode(response);
      return Failure(ApiError.unknown);
    });
  }
}
