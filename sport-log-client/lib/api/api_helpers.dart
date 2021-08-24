
part of 'api.dart';

typedef FromJson<T> = T Function(Map<String, dynamic>);

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

  void _logRequest(String httpMethod, String url, [String? json]) {
    if (json != null) {
      log('$httpMethod $url\n$json', name: 'API request');
    } else {
      log('$httpMethod $url', name: 'API request');
    }
  }

  void _logResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      log('${response.statusCode}\n${response.body}', name: 'API response');
    } else {
      log('${response.statusCode}', name: 'API response');
    }
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

  ApiResult<T> _errorHandling<T>(
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

  ApiResult<List<T>> _getMultiple<T>(String route, {
    required FromJson<T> fromJson,
    ApiError? Function(int)? mapBadStatusToApiError,
    Map<String, String>? headers,
  }) async {
    return _errorHandling<List<T>>((client) async {
      _logRequest('GET', route);
      final response = await client.get(
        _uri(route),
        headers: headers ?? _authorizedHeader,
      );
      _logResponse(response);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic json = jsonDecode(response.body);
        if (json is! List) {
          _logError(response.body);
          return Failure(ApiError.badJson);
        } else {
          final List<T> result = json.map((dynamic j) =>
              fromJson(j as Map<String, dynamic>)
          ).toList();
          return Success(result);
        }
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

  ApiResult<T> _getSingle<T>(String route, {
    required FromJson<T> fromJson,
    ApiError? Function(int)? mapBadStatusToApiError,
    Map<String, String>? headers,
  }) async {
    return _errorHandling<T>((client) async {
      _logRequest('GET', route);
      final response = await client.get(
        _uri(route),
        headers: headers ?? _authorizedHeader,
      );
      _logResponse(response);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return Success(fromJson(
            jsonDecode(response.body) as Map<String, dynamic>));
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

  ApiResult<void> _post(String route, Object body, {
    ApiError? Function(int)? mapBadStatusToApiError,
    Map<String, String>? headers,
  }) async {
    return _errorHandling((client) async {
      final bodyStr = jsonEncode(body);
      _logRequest('POST', route, bodyStr);
      final response = await client.post(
        _uri(route),
        headers: headers ?? _defaultHeaders,
        body: bodyStr,
      );
      _logResponse(response);
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

  ApiResult<void> _put(String route, Object body, {
    ApiError? Function(int)? mapBadStatusToApiError,
  }) async {
    return _errorHandling((client) async {
      final bodyStr = jsonEncode(body);
      _logRequest('PUT', route, bodyStr);
      final response = await client.put(
        _uri(route),
        headers: _defaultHeaders,
        body: bodyStr,
      );
      _logResponse(response);
      if (response.statusCode >= 200 && response.statusCode < 300) {
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