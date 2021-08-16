
part of 'api.dart';

extension Helpers on Api {

  String get _urlBase {
    assert(_urlBaseOptional != null, 'forget to call Api().init()');
    return _urlBaseOptional!;
  }


  Uri _uri(String route) => Uri.parse(_urlBase + route);

  void _logError(String message) {
    stderr.writeln(message);
  }

  void _handleUnknownStatusCode(http.Response response) {
    _logError("status code: ${response.statusCode}; response: ${response.body};");
  }

  Map<String, String> _makeAuthorizedHeader(String username, String password) {
    final basicAuth = 'Basic '
        + base64Encode(utf8.encode('$username:$password'));
    return {
      'authorization': basicAuth
    };
  }

  Map<String, String> get _authorizedHeader {
    assert(_currentUser != null);
    final username = _currentUser!.username;
    final password = _currentUser!.password;
    return _makeAuthorizedHeader(username, password);
  }

  Map<String, String> get _jsonContentTypeHeader => {
    'Content-Type': 'application/json; charset=UTF-8',
  };

  Map<String, String> get _defaultHeaders => {
    ..._authorizedHeader,
    ..._jsonContentTypeHeader,
  };

  Future<Result<T, ApiError>> _request<T>(
      Future<Result<T, ApiError>> Function(http.Client client) req) async {
    try {
      return req(_client);
    } on SocketException {
      return Failure(ApiError.noInternetConnection);
    } catch (e) {
      _logError("Unhandled error: " + e.toString());
      return Failure(ApiError.unhandled);
    }
  }

  Future<Result<T, ApiError>> _get<T>(String route, {
    ApiError? Function(int)? mapBadStatusToApiError,
    Map<String, String>? headers,
  }) async {
    return _request<T>((client) async {
      final response = await client.get(
        _uri(route),
        headers: headers ?? _authorizedHeader,
      );
      if (response.statusCode <= 200 && response.statusCode < 300) {
        final T result = jsonDecode(response.body);
        return Success(result);
      }
      if (mapBadStatusToApiError != null) {
        final ApiError? e = mapBadStatusToApiError(response.statusCode);
        if (e != null) {
          return Failure(e);
        }
      }
      _handleUnknownStatusCode(response);
      return Failure(ApiError.unknown);
    });
  }

  Future<Result<void, ApiError>> _post(String route, Object body, {
    ApiError? Function(int)? mapBadStatusToApiError,
    Map<String, String>? headers,
  }) async {
    return _request((client) async {
      final response = await client.post(
        _uri(route),
        headers: headers ?? _defaultHeaders,
        body: jsonEncode(body),
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return Success(null);
      }
      if (mapBadStatusToApiError != null) {
        final ApiError? e = mapBadStatusToApiError(response.statusCode);
        if (e != null) {
          return Failure(e);
        }
      }
      if (response.statusCode == 409) {
        return Failure(ApiError.conflict);
      }
      _handleUnknownStatusCode(response);
      return Failure(ApiError.unknown);
    });
  }

  Future<Result<void, ApiError>> _put(String route, Object body, {
    ApiError? Function(int)? mapBadStatusToApiError,
  }) async {
    return _request((client) async {
      final response = await client.put(
        _uri(route),
        headers: _defaultHeaders,
        body: jsonEncode(body),
      );
      if (response.statusCode <= 200 && response.statusCode < 300) {
        return Success(null);
      }
      if (mapBadStatusToApiError != null) {
        final ApiError? e = mapBadStatusToApiError(response.statusCode);
        if (e != null) {
          return Failure(e);
        }
      }
      _handleUnknownStatusCode(response);
      return Failure(ApiError.unknown);
    });
  }
}