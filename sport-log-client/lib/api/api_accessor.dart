part of 'api.dart';

abstract class ApiAccessor<T> with ApiHeaders, ApiLogging, ApiHelpers {
  // things needed to be overridden
  T fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson(T object);
  String get singularRoute; // everything after url base, e. g. '/v1.0/user'
  String get pluralRoute => singularRoute + 's';

  // actual methods
  ApiResult<T> getSingle(Int64 id) async {
    return _getRequest(singularRoute + '/$id',
        (dynamic json) => fromJson(json as Map<String, dynamic>));
  }

  ApiResult<List<T>> getMultiple() async {
    return _getRequest(
        singularRoute,
        (dynamic json) => (json as List<dynamic>)
            .map((dynamic json) => fromJson(json as Map<String, dynamic>))
            .toList());
  }

  ApiResult<void> postSingle(T object) async {
    return _errorHandling((client) async {
      final body = toJson(object);
      _logRequest('POST', singularRoute, body);
      final response = await client.post(
        _uri(singularRoute),
        headers: _defaultHeaders,
        body: jsonEncode(body),
      );
      _logResponse(response);
      if (response.statusCode == 409) {
        return Failure(ApiError.conflict);
      }
      if (response.statusCode < 200 && response.statusCode >= 300) {
        return Failure(ApiError.unknown);
      }
      return Success(null);
    });
  }

  ApiResult<void> postMultiple(List<T> objects) async {
    if (objects.isEmpty) {
      return Success(null);
    }
    return _errorHandling((client) async {
      final body = objects.map(toJson).toList();
      _logRequest('POST', pluralRoute, body);
      final response = await client.post(
        _uri(pluralRoute),
        headers: _defaultHeaders,
        body: jsonEncode(body),
      );
      _logResponse(response);
      if (response.statusCode == 409) {
        return Failure(ApiError.conflict);
      }
      if (response.statusCode < 200 && response.statusCode >= 300) {
        return Failure(ApiError.unknown);
      }
      return Success(null);
    });
  }

  ApiResult<void> putSingle(T object) async {
    return _errorHandling((client) async {
      final body = toJson(object);
      _logRequest('PUT', singularRoute, body);
      final response = await client.put(
        _uri(singularRoute),
        headers: _defaultHeaders,
        body: jsonEncode(body),
      );
      _logResponse(response);
      if (response.statusCode < 200 && response.statusCode >= 300) {
        return Failure(ApiError.unknown);
      }
      return Success(null);
    });
  }

  ApiResult<void> putMultiple(List<T> objects) async {
    if (objects.isEmpty) {
      return Success(null);
    }
    return _errorHandling((client) async {
      final body = objects.map(toJson).toList();
      _logRequest('PUT', pluralRoute, body);
      final response = await client.put(
        _uri(pluralRoute),
        headers: _defaultHeaders,
        body: jsonEncode(body),
      );
      _logResponse(response);
      if (response.statusCode < 200 && response.statusCode >= 300) {
        return Failure(ApiError.unknown);
      }
      return Success(null);
    });
  }
}
