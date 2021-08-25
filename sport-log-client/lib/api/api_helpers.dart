part of 'api.dart';

typedef FromJson<T> = T Function(Map<String, dynamic>);

extension Helpers on Api {
  Uri _uri(String route) => Uri.parse(_urlBase + route);

  String _prettyJson(dynamic json, {int indent = 2}) {
    var spaces = ' ' * indent;
    var encoder = JsonEncoder.withIndent(spaces);
    return encoder.convert(json);
  }

  void _handleUnknownStatusCode(http.Response response) {
    _logger
        .e("status code: ${response.statusCode}; response: ${response.body};");
  }

  void _logRequest(String httpMethod, String url, [dynamic json]) {
    if (json != null) {
      final prettyJson = _prettyJson(json);
      _logger.d('request: $httpMethod $url\n$prettyJson');
    } else {
      _logger.d('request: $httpMethod $url');
    }
  }

  void _logResponse(http.Response response) {
    final body = response.body;
    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        body.isNotEmpty) {
      dynamic jsonObject = jsonDecode(body);
      _logger.d('response: ${response.statusCode}\n${_prettyJson(jsonObject)}');
    } else {
      _logger.d('response: ${response.statusCode}');
    }
  }

  Map<String, String> _makeAuthorizedHeader(String username, String password) {
    final basicAuth =
        'Basic ' + base64Encode(utf8.encode('$username:$password'));
    return {'authorization': basicAuth};
  }

  Map<String, String> get _authorizedHeader {
    final user = UserState.instance.currentUser;
    assert(user != null);
    final username = user!.username;
    final password = user.password;
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
      return await req(_client);
    } on SocketException {
      return Failure(ApiError.noInternetConnection);
    } catch (e) {
      _logger.e("Unhandled error: " + e.toString());
      return Failure(ApiError.unhandled);
    }
  }

  ApiResult<List<T>> _getMultiple<T>(
    String route, {
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
          _logger.e('wrong json type');
          return Failure(ApiError.badJson);
        } else {
          final List<T> result = json
              .map((dynamic j) => fromJson(j as Map<String, dynamic>))
              .toList();
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

  ApiResult<T> _getSingle<T>(
    String route, {
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
        return Success(
            fromJson(jsonDecode(response.body) as Map<String, dynamic>));
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

  ApiResult<void> _post(
    String route,
    Object body, {
    ApiError? Function(int)? mapBadStatusToApiError,
    Map<String, String>? headers,
  }) async {
    return _errorHandling((client) async {
      _logRequest('POST', route, body);
      final response = await client.post(
        _uri(route),
        headers: headers ?? _defaultHeaders,
        body: jsonEncode(body),
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

  ApiResult<void> _put(
    String route,
    Object body, {
    ApiError? Function(int)? mapBadStatusToApiError,
  }) async {
    return _errorHandling((client) async {
      _logRequest('PUT', route, body);
      final response = await client.put(
        _uri(route),
        headers: _defaultHeaders,
        body: jsonEncode(body),
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
