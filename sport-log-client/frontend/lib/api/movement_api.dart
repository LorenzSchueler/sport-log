
part of 'api.dart';

extension MovementApi on Api {
  Future<Result<void, ApiError>> createMovement(Movement movement) async {
    return _post(BackendRoutes.movement, movement);
  }

  Future<Result<void, ApiError>> createMovements(
      List<Movement> movements) async {
    return _post(BackendRoutes.movement, movements);
  }

  Future<Result<List<Movement>, ApiError>> getMovements() async {
    return _get<List<Movement>>(BackendRoutes.movement);
  }

  Future<Result<void, ApiError>> updateMovement(Movement movement) async {
    return _put(BackendRoutes.movement, movement);
  }
}
