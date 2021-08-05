
import 'package:sport_log/models/movement.dart';

class MovementRepository {

  final Map<int, Movement> _movements = {};
  
  int get nextMovementId => _movements.length;

  void addMovement(Movement movement) {
    assert(!_movements.containsKey(movement.id));
    _movements[movement.id] = movement;
  }

  void deleteMovement(int id) {
    assert(_movements.containsKey(id));
    _movements.remove(id);
  }

  void updateMovement(Movement movement) {
    assert(_movements.containsKey(movement.id));
    _movements[movement.id] = movement;
  }

  Movement? getMovement(int id) {
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