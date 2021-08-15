
part of 'api.dart';

extension UserRoutes on Api {

  Future<void> createUser(User newUser) async {
    try {
      final response = await _client.post(
        Uri.parse(urlBase + BackendRoutes.user),
        body: jsonEncode(newUser.toJson()),
        headers: _jsonContentTypeHeader,
      );
      if (response.statusCode == 409) {
        throw ApiError.usernameTaken;
      } else if (response.statusCode != 200) {
        _handleUnknownStatusCode(response);
        throw ApiError.unknown;
      }
    } on SocketException {
      throw ApiError.noInternetConnection;
    }
  }

  Future<User> getUser(String username, String password) async {
    try {
      final response = await _client.get(
          Uri.parse(urlBase + BackendRoutes.user),
          headers: _makeAuthorizedHeader(username, password)
      );
      if (response.statusCode == 401) {
        throw ApiError.loginFailed;
      } else if (response.statusCode == 200) {
        return User.fromJson(jsonDecode(response.body));
      } else {
        _handleUnknownStatusCode(response);
        throw ApiError.unknown;
      }
    } on SocketException {
      throw ApiError.noInternetConnection;
    }
  }
}