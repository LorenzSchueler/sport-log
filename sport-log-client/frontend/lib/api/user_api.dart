
part of 'api.dart';

extension UserRoutes on Api {
  ApiResult<void> createUser(User user) async {
    final result = await _post(
        BackendRoutes.user,
        user,
        headers: _jsonContentTypeHeader,
        mapBadStatusToApiError: (statusCode) {
          if (statusCode == 409) {
            return ApiError.usernameTaken;
          }
        });
    if (result.isSuccess) {
      _currentUser = user;
    }
    return result;
  }

  ApiResult<User> getUser(String username, String password) async {
    final result = await _getSingle<User>(
      BackendRoutes.user,
      fromJson: (json) => User.fromJson(json),
      headers: _makeAuthorizedHeader(username, password),
      mapBadStatusToApiError: (statusCode) {
        if (statusCode == 401) {
          return ApiError.loginFailed;
        }
      });
    if (result.isSuccess) {
      _currentUser = result.success;
    }
    return result;
  }

  ApiResult<void> updateUser(User user) async {
    final result = await _put(BackendRoutes.user, user);
    if (result.isSuccess) {
      _currentUser = user;
    }
    return result;
  }

  ApiResult<void> deleteUser() async {
    return _request((client) async {
      final response = await client.delete(
        _uri(BackendRoutes.user),
        headers: _authorizedHeader
      );
      if (response.statusCode <= 200 && response.statusCode < 300) {
        _currentUser = null;
        return Success(null);
      }
      _handleUnknownStatusCode(response);
      return Failure(ApiError.unknown);
    });
  }
}