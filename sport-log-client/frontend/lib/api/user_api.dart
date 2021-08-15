
part of 'api.dart';

extension UserRoutes on Api {
  ApiResult<void> createUser(User user) async {
    return _post(
        BackendRoutes.user,
        user,
        headers: _jsonContentTypeHeader,
        mapBadStatusToApiError: (statusCode) {
          if (statusCode == 409) {
            return ApiError.usernameTaken;
          }
        });
  }

  ApiResult<User> getUser(String username, String password) async {
    return _get(
      BackendRoutes.user,
      headers: _makeAuthorizedHeader(username, password),
      mapBadStatusToApiError: (statusCode) {
        if (statusCode == 401) {
          return ApiError.loginFailed;
        }
      });
  }

  ApiResult<void> updateUser(User user) async {
    return _put(BackendRoutes.user, user);
  }

  ApiResult<void> deleteUser() async {
    return _request((client) async {
      final response = await client.delete(
        _uri(BackendRoutes.user),
        headers: _authorizedHeader
      );
      if (response.statusCode <= 200 && response.statusCode < 300) {
        return Success(null);
      }
      _handleUnknownStatusCode(response);
      return Failure(ApiError.unknown);
    });
  }
}