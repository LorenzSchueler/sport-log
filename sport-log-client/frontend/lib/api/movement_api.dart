
part of 'api.dart';

extension MovementApi on Api {
  Future<Result<void, ApiError>> createMovement(Movement movement) async {
    return _request((client) async {
      final response = await _client.post(
        _uri(BackendRoutes.movement),
        headers: _defaultHeaders,
        body: jsonEncode(movement),
      );
      if (response.statusCode != 200) {
        _handleUnknownStatusCode(response);
        return Failure(ApiError.unknown);
      }
      return Success(null);
    });
  }

  Future<Result<void, ApiError>> createMovements(
      List<Movement> movements) async {
    return _request((client) async {
      final response = await client.post(
        _uri(BackendRoutes.movement),
        headers: _defaultHeaders,
        body: jsonEncode(movements),
      );
      if (response.statusCode != 200) {
        _handleUnknownStatusCode(response);
        return Failure(ApiError.unknown);
      }
      return Success(null);
    });
  }

  Future<Result<List<Movement>, ApiError>> getMovements() async {
    return _get<List<Movement>>(BackendRoutes.movement);
  }

  Future<Result<void, ApiError>> updateMovement(Movement movement) async {
    return _request((client) async {
      final response = await client.post(
        _uri(BackendRoutes.movement),
        headers: _defaultHeaders,
        body: jsonEncode(movement),
      );
      if (response.statusCode == 200) {
        return Success(null);
      } else {
        _handleUnknownStatusCode(response);
        return Failure(ApiError.unknown);
      }
    });
  }

  Future<Result<void, ApiError>> updateMovements(
      List<Movement> movements) async {
    return _request((client) {
    });
  }
}
