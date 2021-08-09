
import 'package:fixnum/fixnum.dart';
import 'package:sport_log/models/movement/movement.dart';

class MovementRepository {

  final Map<Int64, Movement> _movements = {};

  static Int64 _nextMovementId = Int64(0);
  Int64 get nextMovementId => _nextMovementId++;

  void addMovement(Movement movement) {
    assert(!_movements.containsKey(movement.id));
    _movements[movement.id] = movement;
  }

  void addAllMovements(List<Movement> movements) {
    for (final movement in movements) {
      addMovement(movement);
    }
  }

  void deleteMovement(Int64 id) {
    assert(_movements.containsKey(id));
    _movements.remove(id);
  }

  void updateMovement(Movement movement) {
    assert(_movements.containsKey(movement.id));
    _movements[movement.id] = movement;
  }

  Movement? getMovement(Int64 id) {
    if (!_movements.containsKey(id)) {
      return null;
    }
    return _movements[id];
  }

  List<Movement> getAllMovements() {
    return _movements.values.toList();
  }

  List<Movement> searchByName(String search) {
    if (search.isEmpty) {
      return getAllMovements();
    }
    final s = search.toLowerCase();
    return _movements.values.where((m) =>
        m.name.toLowerCase().contains(s)).toList();
  }
}