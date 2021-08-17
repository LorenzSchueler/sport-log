
part of 'api.dart';

extension MovementRoutes on Api {
  ApiResult<void> createMovement(Movement movement) async {
    return _post(BackendRoutes.movement, movement);
  }

  ApiResult<void> createMovements(
      List<Movement> movements) async {
    return _post(BackendRoutes.movement, movements);
  }

  ApiResult<List<Movement>> getMovements() async {
    return _getMultiple(BackendRoutes.movement,
        fromJson: (json) => Movement.fromJson(json));
  }

  ApiResult<Movement> getMovement(Int64 id) async {
    return _getSingle(BackendRoutes.movement + '/$id',
        fromJson: (json) => Movement.fromJson(json));
  }

  ApiResult<void> updateMovement(Movement movement) async {
    return _put(BackendRoutes.movement, movement);
  }
}
